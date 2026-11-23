// CryptoKit.framework under Darling: known-answer tests for the elliptic-curve primitives: X25519, Ed25519, P-256 ECDSA verification and
// P-256 ECDH, plus checks that keys, nonces and signatures drawn from the random sources differ and work (getentropy under Darling).
//
// Vector groups and their sources:
//   - X25519: RFC 7748 section 6.1 (https://www.rfc-editor.org/rfc/rfc7748#section-6.1).
//   - Ed25519: RFC 8032 section 7.1, TEST 1 (empty message) and TEST 2 (one byte message 0x72) (https://www.rfc-editor.org/rfc/rfc8032#section-7.1).
//   - P-256 ECDSA: RFC 6979 appendix A.2.5, key pair and the SHA-256 signatures of "sample" and "test" (https://www.rfc-editor.org/rfc/rfc6979#appendix-A.2.5).
//   - P-256 ECDH: RFC 5903 section 8.1, the 256-bit random ECP group (https://www.rfc-editor.org/rfc/rfc5903#section-8.1).
// Each value was parsed from the text of the cited public document and recomputed on the host with openssl, python3 hashlib/hmac or libcrypto
// (the commit that adds this file has the commands). The documents are public standards used for their test data only: no prose of
// an RFC or NIST text is copied here (RFC text is published under the IETF Trust's Legal Provisions; the vectors are data).
// Uses only API that Apple documents for CryptoKit.
import CryptoKit
import Foundation

setvbuf(stdout, nil, _IOLBF, 0)  // line buffered, so the output up to a crash is not lost in the pipe

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

func hex<S: Sequence>(_ bytes: S) -> String where S.Element == UInt8 {
    bytes.map { byte in
        let digits = String(byte, radix: 16)
        return digits.count == 1 ? "0" + digits : digits
    }.joined()
}

func unhex(_ s: String) -> Data {
    var out = Data()
    var index = s.startIndex
    while index < s.endIndex {
        let next = s.index(index, offsetBy: 2)
        out.append(UInt8(s[index..<next], radix: 16)!)
        index = next
    }
    return out
}

func flipped(_ data: Data, bit: Int = 0) -> Data {
    var copy = data
    copy[copy.startIndex + bit / 8] ^= UInt8(1 << (bit % 8))
    return copy
}

// Runs a body that may throw; a throw is a FAIL line with the error, not a crash.
func attempt(_ label: String, _ body: () throws -> Void) {
    do { try body() } catch { check(false, "\(label) threw \(error)") }
}

func throwsError(_ body: () throws -> Void) -> Bool {
    do { try body() } catch { return true }
    return false
}

func section(_ name: String) { print("--- \(name)") }

// RFC 7748 section 6.1 (X25519 test vector).
let x_alice_priv = "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a"
let x_alice_pub = "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a"
let x_bob_priv = "5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb"
let x_bob_pub = "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f"
let x_shared = "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742"

// RFC 8032 section 7.1, TEST 1 (empty message) and TEST 2 (one byte message 0x72) for Ed25519.
let ed1_sk = "9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60"
let ed1_pk = "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a"
let ed1_msg = ""
let ed1_sig = "e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b"
let ed2_sk = "4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb"
let ed2_pk = "3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c"
let ed2_msg = "72"
let ed2_sig = "92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00"

// RFC 6979 appendix A.2.5 (NIST P-256 key pair; ECDSA signatures with SHA-256 of the messages "sample" and "test").
let p256_x = "c9afa9d845ba75166b5c215767b1d6934e50c3db36e89b127b8a622b120f6721"
let p256_Ux = "60fed4ba255a9d31c961eb74c6356d68c049b8923b61fa6ce669622e60f29fb6"
let p256_Uy = "7903fe1008b8bc99a41ae9e95628bc64f2f1b20c2d7e9f5177a3c294d4462299"
let p256_sha256_sample_r = "efd48b2aacb6a8fd1140dd9cd45e81d69d2c877b56aaf991c34d0ea84eaf3716"
let p256_sha256_sample_s = "f7cb1c942d657c41d436c7a1b6e29f65f3e900dbb9aff4064dc4ab2f843acda8"
let p256_sha256_test_r = "f1abb023518351cd71d881567b1ea663ed3efcf6c5132b354f28d3b0b7d38367"
let p256_sha256_test_s = "019f4113742a2b14bd25926b49c649155f267e60d3814b4c0cc84250e46f0083"

// RFC 5903 section 8.1 (256-bit random ECP group, ECDH): initiator private i and public (gix,giy), responder private r and public (grx,gry),
// common value (girx,giry); the shared secret is girx.
let ecdh_i = "c88f01f510d9ac3f70a292daa2316de544e9aab8afe84049c62a9c57862d1433"
let ecdh_gix = "dad0b65394221cf9b051e1feca5787d098dfe637fc90b9ef945d0c3772581180"
let ecdh_giy = "5271a0461cdb8252d61f1c456fa3e59ab1f45b33accf5f58389e0577b8990bb3"
let ecdh_r = "c6ef9c5d78ae012a011164acb397ce2088685d8f06bf9be0b283ab46476bee53"
let ecdh_grx = "d12dfb5289c8d4f81208b70270398c342296970a0bccb74c736fc7554494bf63"
let ecdh_gry = "56fbf3ca366cc23e8157854c13c58d6aac23f046ada30f8353e74f33039872ab"
let ecdh_girx = "d6840f6b42f6edafd13116e0e12565202fef8e9ece7dce03812464d04b9442de"
let ecdh_giry = "522bde0af0d8585b8def9c183b5ae38f50235206a8674ecb5d98edb20eb153a2"

// ---------------------------------------------------------------------------------------------------------------------------------
section("X25519 (RFC 7748 section 6.1)")
attempt("X25519") {
    let alice = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: unhex(x_alice_priv))
    let bob = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: unhex(x_bob_priv))
    check(hex(alice.publicKey.rawRepresentation) == x_alice_pub, "X25519 public key of Alice's private key")
    check(hex(bob.publicKey.rawRepresentation) == x_bob_pub, "X25519 public key of Bob's private key")
    let alicePublic = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: unhex(x_alice_pub))
    let bobPublic = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: unhex(x_bob_pub))
    let sharedAlice = try alice.sharedSecretFromKeyAgreement(with: bobPublic)
    let sharedBob = try bob.sharedSecretFromKeyAgreement(with: alicePublic)
    check(sharedAlice.withUnsafeBytes { hex($0) } == x_shared, "X25519 shared secret computed by Alice")
    check(sharedBob.withUnsafeBytes { hex($0) } == x_shared, "X25519 shared secret computed by Bob")
    let other = Curve25519.KeyAgreement.PrivateKey()
    let sharedOther = try other.sharedSecretFromKeyAgreement(with: bobPublic)
    check(sharedOther.withUnsafeBytes { hex($0) } != x_shared, "X25519 shared secret with another private key differs")
}

// ---------------------------------------------------------------------------------------------------------------------------------
section("Ed25519 (RFC 8032 section 7.1)")
for (number, sk, pk, msg, sig) in [(1, ed1_sk, ed1_pk, ed1_msg, ed1_sig), (2, ed2_sk, ed2_pk, ed2_msg, ed2_sig)] {
    attempt("Ed25519 TEST \(number)") {
        let key = try Curve25519.Signing.PrivateKey(rawRepresentation: unhex(sk))
        let message = unhex(msg)
        check(hex(key.publicKey.rawRepresentation) == pk, "Ed25519 TEST \(number): public key")
        let signature = try key.signature(for: message)
        check(hex(signature) == sig, "Ed25519 TEST \(number): signature (deterministic)")
        let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: unhex(pk))
        check(publicKey.isValidSignature(unhex(sig), for: message), "Ed25519 TEST \(number): published signature is valid")
        check(!publicKey.isValidSignature(flipped(unhex(sig), bit: 3), for: message), "Ed25519 TEST \(number): signature with a flipped bit is invalid")
        check(!publicKey.isValidSignature(flipped(unhex(sig), bit: 400), for: message), "Ed25519 TEST \(number): signature with a flipped bit in S is invalid")
        check(!publicKey.isValidSignature(unhex(sig), for: message + Data([0])), "Ed25519 TEST \(number): published signature of another message is invalid")
        let otherKey = Curve25519.Signing.PrivateKey()
        check(!otherKey.publicKey.isValidSignature(unhex(sig), for: message), "Ed25519 TEST \(number): signature under another public key is invalid")
    }
}

// ---------------------------------------------------------------------------------------------------------------------------------
section("P-256 ECDSA (RFC 6979 appendix A.2.5)")
attempt("P-256 ECDSA") {
    let uncompressed = unhex("04" + p256_Ux + p256_Uy)
    let privateKey = try P256.Signing.PrivateKey(rawRepresentation: unhex(p256_x))
    check(privateKey.publicKey.x963Representation == uncompressed, "P256.Signing public key of the published private key")
    let publicKey = try P256.Signing.PublicKey(x963Representation: uncompressed)
    let sample = Data("sample".utf8)
    let test = Data("test".utf8)
    let sampleSignature = try P256.Signing.ECDSASignature(rawRepresentation: unhex(p256_sha256_sample_r + p256_sha256_sample_s))
    let testSignature = try P256.Signing.ECDSASignature(rawRepresentation: unhex(p256_sha256_test_r + p256_sha256_test_s))
    check(publicKey.isValidSignature(sampleSignature, for: sample), "P256 verify of (r,s) for \"sample\" with SHA-256 over the data")
    check(publicKey.isValidSignature(sampleSignature, for: SHA256.hash(data: sample)), "P256 verify of (r,s) for \"sample\" with the SHA256 digest")
    check(publicKey.isValidSignature(testSignature, for: test), "P256 verify of (r,s) for \"test\" with SHA-256 over the data")
    check(!publicKey.isValidSignature(sampleSignature, for: test), "P256 verify of the \"sample\" signature against \"test\" fails")
    check(!publicKey.isValidSignature(testSignature, for: sample), "P256 verify of the \"test\" signature against \"sample\" fails")
    let flippedR = try P256.Signing.ECDSASignature(rawRepresentation: flipped(sampleSignature.rawRepresentation, bit: 9))
    check(!publicKey.isValidSignature(flippedR, for: sample), "P256 verify with a flipped bit in r fails")
    let flippedS = try P256.Signing.ECDSASignature(rawRepresentation: flipped(sampleSignature.rawRepresentation, bit: 300))
    check(!publicKey.isValidSignature(flippedS, for: sample), "P256 verify with a flipped bit in s fails")
    // a signature made here (random k) must verify, and not for other data
    let fresh = try privateKey.signature(for: sample)
    check(publicKey.isValidSignature(fresh, for: sample), "P256 signature made by CryptoKit verifies")
    check(!publicKey.isValidSignature(fresh, for: test), "P256 signature made by CryptoKit does not verify for other data")
    check(fresh.rawRepresentation.count == 64, "P256 raw signature is 64 bytes")
    let reparsed = try P256.Signing.ECDSASignature(derRepresentation: sampleSignature.derRepresentation)
    check(reparsed.rawRepresentation == sampleSignature.rawRepresentation, "P256 signature DER round trip")
}

// ---------------------------------------------------------------------------------------------------------------------------------
section("P-256 ECDH (RFC 5903 section 8.1)")
attempt("P-256 ECDH") {
    let initiator = try P256.KeyAgreement.PrivateKey(rawRepresentation: unhex(ecdh_i))
    let responder = try P256.KeyAgreement.PrivateKey(rawRepresentation: unhex(ecdh_r))
    check(initiator.publicKey.x963Representation == unhex("04" + ecdh_gix + ecdh_giy), "P256.KeyAgreement public key of i")
    check(responder.publicKey.x963Representation == unhex("04" + ecdh_grx + ecdh_gry), "P256.KeyAgreement public key of r")
    let initiatorPublic = try P256.KeyAgreement.PublicKey(x963Representation: unhex("04" + ecdh_gix + ecdh_giy))
    let responderPublic = try P256.KeyAgreement.PublicKey(x963Representation: unhex("04" + ecdh_grx + ecdh_gry))
    let sharedI = try initiator.sharedSecretFromKeyAgreement(with: responderPublic)
    let sharedR = try responder.sharedSecretFromKeyAgreement(with: initiatorPublic)
    check(sharedI.withUnsafeBytes { hex($0) } == ecdh_girx, "P256 shared secret computed by the initiator is girx")
    check(sharedR.withUnsafeBytes { hex($0) } == ecdh_girx, "P256 shared secret computed by the responder is girx")
    check(throwsError { _ = try P256.KeyAgreement.PublicKey(x963Representation: unhex("04" + ecdh_gix + ecdh_gix)) },
          "P256.KeyAgreement.PublicKey rejects a point that is not on the curve")
}

// ---------------------------------------------------------------------------------------------------------------------------------
section("randomness (getentropy under Darling)")
let randomA = SymmetricKey(size: .bits256)
let randomB = SymmetricKey(size: .bits256)
check(!(randomA == randomB), "two SymmetricKey(size: .bits256) differ")
check(randomA.withUnsafeBytes { Array($0).contains { $0 != 0 } }, "a random SymmetricKey is not all zero")
let xA = Curve25519.KeyAgreement.PrivateKey()
let xB = Curve25519.KeyAgreement.PrivateKey()
check(xA.publicKey.rawRepresentation != xB.publicKey.rawRepresentation, "two Curve25519.KeyAgreement keys have different public keys")
let eA = Curve25519.Signing.PrivateKey()
let eB = Curve25519.Signing.PrivateKey()
check(eA.publicKey.rawRepresentation != eB.publicKey.rawRepresentation, "two Curve25519.Signing keys have different public keys")
let pA = P256.Signing.PrivateKey()
let pB = P256.Signing.PrivateKey()
check(pA.publicKey.x963Representation != pB.publicKey.x963Representation, "two P256.Signing keys have different public keys")
check(hex(AES.GCM.Nonce()) != hex(AES.GCM.Nonce()), "two AES.GCM.Nonce() values differ")
attempt("random round trip") {
    let key = SymmetricKey(size: .bits256)
    let message = Data("random key and nonce round trip".utf8)
    let box = try AES.GCM.seal(message, using: key)
    check(try AES.GCM.open(box, using: key) == message, "AES.GCM seal with a random nonce, then open")
    let box2 = try ChaChaPoly.seal(message, using: key)
    check(try ChaChaPoly.open(box2, using: key) == message, "ChaChaPoly seal with a random nonce, then open")
}

print(failures == 0 ? "PASS: cryptokit_kat_curves" : "FAIL: cryptokit_kat_curves, \(failures) checks failed")
if failures != 0 { exit(1) }
