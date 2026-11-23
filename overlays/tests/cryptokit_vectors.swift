// Copyright (C) 2026 Lubos Dolezel
//
// CryptoKit.framework under Darling: known-answer tests for SHA-256, HMAC-SHA-256, AES-GCM, X25519 and Ed25519
// against published vectors, plus the documented failure behaviour of the authenticated and key-parsing APIs. Uses
// only API that Apple documents for CryptoKit.
//
// Vectors:
//   - SHA-256 of "abc", of the empty string and of the 448-bit message "abcdbcdecdefdefg...nopnopq": the examples
//     of NIST FIPS 180-4 (https://csrc.nist.gov/pubs/fips/180-4/upd1/final).
//   - HMAC-SHA-256 test cases 1, 2 and 6 of RFC 4231, section 4 (https://www.rfc-editor.org/rfc/rfc4231#section-4).
//   - AES-128-GCM test cases 1 to 4 of "The Galois/Counter Mode of Operation (GCM)" by McGrew and Viega, the
//     vectors that NIST SP 800-38D points to (https://csrc.nist.gov/pubs/sp/800/38/d/final; the original
//     submission is at https://csrc.nist.gov/CSRC/media/Projects/Block-Cipher-Techniques/documents/BCM/proposedmodes/gcm/gcm-spec.pdf).
//   - X25519: the Alice and Bob key pairs and shared secret of RFC 7748, section 6.1
//     (https://www.rfc-editor.org/rfc/rfc7748#section-6.1).
//   - Ed25519: tests 1 (empty message) and 2 (one-byte message) of RFC 8032, section 7.1
//     (https://www.rfc-editor.org/rfc/rfc8032#section-7.1).
import CryptoKit
import Foundation

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

func bytes(_ hexString: String) -> Data {
    var result = Data()
    var index = hexString.startIndex
    while index < hexString.endIndex {
        let next = hexString.index(index, offsetBy: 2)
        result.append(UInt8(hexString[index..<next], radix: 16)!)
        index = next
    }
    return result
}

// SHA-256 (FIPS 180-4)
check(hex(SHA256.hash(data: Data("abc".utf8))) == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
      "SHA256 \"abc\"")
check(hex(SHA256.hash(data: Data())) == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
      "SHA256 empty message")
check(hex(SHA256.hash(data: Data("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq".utf8)))
        == "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1", "SHA256 448-bit message")
check(SHA256.byteCount == 32 && SHA256.blockByteCount == 64, "SHA256 sizes")

// HMAC-SHA-256 (RFC 4231)
let hmac1 = HMAC<SHA256>.authenticationCode(for: Data("Hi There".utf8),
                                            using: SymmetricKey(data: Data(repeating: 0x0b, count: 20)))
check(hex(hmac1) == "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7", "HMAC<SHA256> RFC 4231 case 1")
let hmac2 = HMAC<SHA256>.authenticationCode(for: Data("what do ya want for nothing?".utf8),
                                            using: SymmetricKey(data: Data("Jefe".utf8)))
check(hex(hmac2) == "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843", "HMAC<SHA256> RFC 4231 case 2")
let hmac6 = HMAC<SHA256>.authenticationCode(
    for: Data("Test Using Larger Than Block-Size Key - Hash Key First".utf8),
    using: SymmetricKey(data: Data(repeating: 0xaa, count: 131)))
check(hex(hmac6) == "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54",
      "HMAC<SHA256> RFC 4231 case 6 (key longer than the block)")
check(HMAC<SHA256>.isValidAuthenticationCode(hmac2, authenticating: Data("what do ya want for nothing?".utf8),
                                             using: SymmetricKey(data: Data("Jefe".utf8))), "HMAC isValidAuthenticationCode")
check(!HMAC<SHA256>.isValidAuthenticationCode(hmac2, authenticating: Data("what do ya want for nothing!".utf8),
                                              using: SymmetricKey(data: Data("Jefe".utf8))),
      "HMAC isValidAuthenticationCode rejects another message")

// AES-128-GCM (McGrew and Viega, test cases 1 to 4)
let zeroKey = SymmetricKey(data: Data(repeating: 0, count: 16))
let case1 = try! AES.GCM.seal(Data(), using: zeroKey, nonce: AES.GCM.Nonce(data: Data(repeating: 0, count: 12)))
check(case1.ciphertext.isEmpty && hex(case1.tag) == "58e2fccefa7e3061367f1d57a4e7455a", "AES.GCM test case 1")
let case2 = try! AES.GCM.seal(Data(repeating: 0, count: 16), using: zeroKey,
                              nonce: AES.GCM.Nonce(data: Data(repeating: 0, count: 12)))
check(hex(case2.ciphertext) == "0388dace60b6a392f328c2b971b2fe78" && hex(case2.tag) == "ab6e47d42cec13bdf53a67b21257bddf",
      "AES.GCM test case 2")

let key34 = SymmetricKey(data: bytes("feffe9928665731c6d6a8f9467308308"))
let nonce34 = try! AES.GCM.Nonce(data: bytes("cafebabefacedbaddecaf888"))
let plain3 = bytes("d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255")
let cipher3 = "42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091473f5985"
let case3 = try! AES.GCM.seal(plain3, using: key34, nonce: nonce34)
check(hex(case3.ciphertext) == cipher3 && hex(case3.tag) == "4d5c2af327cd64a62cf35abd2ba6fab4", "AES.GCM test case 3")

let plain4 = plain3.prefix(60)
let aad4 = bytes("feedfacedeadbeeffeedfacedeadbeefabaddad2")
let case4 = try! AES.GCM.seal(plain4, using: key34, nonce: nonce34, authenticating: aad4)
check(hex(case4.ciphertext) == String(cipher3.prefix(120)) && hex(case4.tag) == "5bc94fbc3221a5db94fae95ae7121a47",
      "AES.GCM test case 4 (with additional data)")
check(case4.combined?.count == 12 + 60 + 16, "AES.GCM combined layout nonce || ciphertext || tag")
check((try? AES.GCM.open(case4, using: key34, authenticating: aad4)) == Data(plain4), "AES.GCM open round trip")
let reparsed = try! AES.GCM.SealedBox(combined: case4.combined!)
check((try? AES.GCM.open(reparsed, using: key34, authenticating: aad4)) == Data(plain4),
      "AES.GCM SealedBox(combined:) then open")

// failure behaviour: wrong additional data, flipped ciphertext bit, wrong key, bad nonce and key sizes
check((try? AES.GCM.open(case4, using: key34, authenticating: Data("other".utf8))) == nil,
      "AES.GCM open with other additional data fails")
var flipped = case4.combined!
flipped[20] ^= 1
check((try? AES.GCM.open(try AES.GCM.SealedBox(combined: flipped), using: key34, authenticating: aad4)) == nil,
      "AES.GCM open of a modified ciphertext fails")
check((try? AES.GCM.open(case4, using: zeroKey, authenticating: aad4)) == nil, "AES.GCM open with the wrong key fails")
var authenticationFailure = false
do { _ = try AES.GCM.open(case4, using: zeroKey, authenticating: aad4) } catch CryptoKitError.authenticationFailure {
    authenticationFailure = true
} catch {}
check(authenticationFailure, "AES.GCM open failure is CryptoKitError.authenticationFailure")
check((try? AES.GCM.Nonce(data: Data(repeating: 0, count: 5))) == nil, "AES.GCM.Nonce rejects 5 bytes")
check((try? AES.GCM.seal(Data("x".utf8), using: SymmetricKey(data: Data(repeating: 0, count: 5)))) == nil,
      "AES.GCM seal rejects a 5-byte key")
check((try? AES.GCM.SealedBox(combined: Data(repeating: 0, count: 10))) == nil,
      "AES.GCM.SealedBox(combined:) rejects data shorter than nonce and tag")
let generated = try! AES.GCM.seal(Data("round trip".utf8), using: SymmetricKey(size: .bits256))
check(generated.ciphertext.count == 10 && generated.nonce.withUnsafeBytes { $0.count } == 12, "AES.GCM random nonce and 256-bit key")

// X25519 (RFC 7748 section 6.1)
let alice = try! Curve25519.KeyAgreement.PrivateKey(
    rawRepresentation: bytes("77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a"))
let bob = try! Curve25519.KeyAgreement.PrivateKey(
    rawRepresentation: bytes("5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb"))
check(hex(alice.publicKey.rawRepresentation) == "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a",
      "X25519 Alice public key")
check(hex(bob.publicKey.rawRepresentation) == "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f",
      "X25519 Bob public key")
let sharedA = try! alice.sharedSecretFromKeyAgreement(with: bob.publicKey)
let sharedB = try! bob.sharedSecretFromKeyAgreement(with: alice.publicKey)
let expectedShared = "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742"
check(sharedA.withUnsafeBytes { hex($0) } == expectedShared, "X25519 shared secret, Alice side")
check(sharedB.withUnsafeBytes { hex($0) } == expectedShared, "X25519 shared secret, Bob side")
check(sharedA == sharedB, "SharedSecret equality")
check((try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: Data(repeating: 1, count: 31))) == nil,
      "X25519 private key rejects 31 bytes")
check((try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: Data(repeating: 1, count: 33))) == nil,
      "X25519 public key rejects 33 bytes")
let derived = sharedA.hkdfDerivedSymmetricKey(using: SHA256.self, salt: Data(), sharedInfo: Data(), outputByteCount: 32)
check(derived.bitCount == 256, "SharedSecret.hkdfDerivedSymmetricKey size")

// Ed25519 (RFC 8032 section 7.1)
let signer1 = try! Curve25519.Signing.PrivateKey(
    rawRepresentation: bytes("9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60"))
check(hex(signer1.publicKey.rawRepresentation) == "d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a",
      "Ed25519 test 1 public key")
let sig1 = bytes("e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b")
check(signer1.publicKey.isValidSignature(sig1, for: Data()), "Ed25519 test 1 signature verifies")
check(!signer1.publicKey.isValidSignature(sig1, for: Data([0])), "Ed25519 test 1 signature rejects another message")
check(signer1.publicKey.isValidSignature(try! signer1.signature(for: Data("message".utf8)), for: Data("message".utf8)),
      "Ed25519 own signature verifies")
let signer2 = try! Curve25519.Signing.PrivateKey(
    rawRepresentation: bytes("4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb"))
check(hex(signer2.publicKey.rawRepresentation) == "3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c",
      "Ed25519 test 2 public key")
let sig2 = bytes("92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00")
check(signer2.publicKey.isValidSignature(sig2, for: Data([0x72])), "Ed25519 test 2 signature verifies")
var badSig = sig2
badSig[10] ^= 1
check(!signer2.publicKey.isValidSignature(badSig, for: Data([0x72])), "Ed25519 modified signature is rejected")
check((try? Curve25519.Signing.PublicKey(rawRepresentation: Data(repeating: 1, count: 31))) == nil,
      "Ed25519 public key rejects 31 bytes")

print(failures == 0 ? "PASS: cryptokit_vectors" : "FAIL: cryptokit_vectors, \(failures) checks failed")
if failures != 0 { exit(1) }
