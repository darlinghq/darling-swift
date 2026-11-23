// CryptoKit.framework under Darling: known-answer tests for the AEAD primitives: ChaCha20-Poly1305 and AES-GCM (128, 192 and 256-bit keys),
// each with tamper checks (flipped tag, ciphertext, authenticated data, wrong key), and a seal/open round trip with a random nonce.
//
// Vector groups and their sources:
//   - ChaCha20-Poly1305: RFC 8439 section 2.8.2 (https://www.rfc-editor.org/rfc/rfc8439#section-2.8.2).
//   - AES-GCM: McGrew and Viega, "The Galois/Counter Mode of Operation (GCM)", NIST submission, Appendix B, test cases 1-4 (AES-128), 7-8 (AES-192)
//     and 13-16 (AES-256) (https://csrc.nist.rip/groups/ST/toolkit/BCM/documents/proposedmodes/gcm/gcm-spec.pdf). Only the 96-bit IV cases are used,
//     the only IV size that CryptoKit's AES.GCM.Nonce documents as default; the cases with other IV sizes (5, 6, 9-12, 17, 18) are not covered.
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

// RFC 8439 section 2.8.2 (AEAD_CHACHA20_POLY1305). Nonce = 32-bit fixed part 07000000 followed by the 8-byte IV 4041424344454647.
let chacha_pt = "4c616469657320616e642047656e746c656d656e206f662074686520636c617373206f66202739393a204966204920636f756c64206f6666657220796f75206f6e6c79206f6e652074697020666f7220746865206675747572652c2073756e73637265656e20776f756c642062652069742e"
let chacha_aad = "50515253c0c1c2c3c4c5c6c7"
let chacha_key = "808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f"
let chacha_fixed = "07000000"
let chacha_iv = "4041424344454647"
let chacha_ct = "d31a8d34648e60db7b86afbc53ef7ec2a4aded51296e08fea9e2b5a736ee62d63dbea45e8ca9671282fafb69da92728b1a71de0a9e060b2905d6a5b67ecd3b3692ddbd7f2d778b8c9803aee328091b58fab324e4fad675945585808b4831d7bc3ff4def08e4b7a9de576d26586cec64b6116"
let chacha_tag = "1ae10b594f09e26a7e902ecbd0600691"

// McGrew and Viega, "The Galois/Counter Mode of Operation (GCM)", NIST submission, Appendix B test cases
// (https://csrc.nist.rip/groups/ST/toolkit/BCM/documents/proposedmodes/gcm/gcm-spec.pdf). K key, P plaintext, A additional data, IV, C ciphertext, T tag.
// Only the cases with a 96-bit IV (the only IV size CryptoKit's AES.GCM.Nonce guarantees): 1-4 (AES-128), 7-8 (AES-192), 13-16 (AES-256).
let gcm1_K = "00000000000000000000000000000000"
let gcm1_P = ""
let gcm1_IV = "000000000000000000000000"
let gcm1_C = ""
let gcm1_T = "58e2fccefa7e3061367f1d57a4e7455a"
let gcm2_K = "00000000000000000000000000000000"
let gcm2_P = "00000000000000000000000000000000"
let gcm2_IV = "000000000000000000000000"
let gcm2_C = "0388dace60b6a392f328c2b971b2fe78"
let gcm2_T = "ab6e47d42cec13bdf53a67b21257bddf"
let gcm3_K = "feffe9928665731c6d6a8f9467308308"
let gcm3_P = "d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255"
let gcm3_IV = "cafebabefacedbaddecaf888"
let gcm3_C = "42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091473f5985"
let gcm3_T = "4d5c2af327cd64a62cf35abd2ba6fab4"
let gcm4_K = "feffe9928665731c6d6a8f9467308308"
let gcm4_P = "d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39"
let gcm4_A = "feedfacedeadbeeffeedfacedeadbeefabaddad2"
let gcm4_IV = "cafebabefacedbaddecaf888"
let gcm4_C = "42831ec2217774244b7221b784d0d49ce3aa212f2c02a4e035c17e2329aca12e21d514b25466931c7d8f6a5aac84aa051ba30b396a0aac973d58e091"
let gcm4_T = "5bc94fbc3221a5db94fae95ae7121a47"
let gcm7_K = "000000000000000000000000000000000000000000000000"
let gcm7_P = ""
let gcm7_IV = "000000000000000000000000"
let gcm7_C = ""
let gcm7_T = "cd33b28ac773f74ba00ed1f312572435"
let gcm8_K = "000000000000000000000000000000000000000000000000"
let gcm8_P = "00000000000000000000000000000000"
let gcm8_IV = "000000000000000000000000"
let gcm8_C = "98e7247c07f0fe411c267e4384b0f600"
let gcm8_T = "2ff58d80033927ab8ef4d4587514f0fb"
let gcm13_K = "0000000000000000000000000000000000000000000000000000000000000000"
let gcm13_P = ""
let gcm13_IV = "000000000000000000000000"
let gcm13_C = ""
let gcm13_T = "530f8afbc74536b9a963b4f1c4cb738b"
let gcm14_K = "0000000000000000000000000000000000000000000000000000000000000000"
let gcm14_P = "00000000000000000000000000000000"
let gcm14_IV = "000000000000000000000000"
let gcm14_C = "cea7403d4d606b6e074ec5d3baf39d18"
let gcm14_T = "d0d1c8a799996bf0265b98b5d48ab919"
let gcm15_K = "feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308"
let gcm15_P = "d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b391aafd255"
let gcm15_IV = "cafebabefacedbaddecaf888"
let gcm15_C = "522dc1f099567d07f47f37a32a84427d643a8cdcbfe5c0c97598a2bd2555d1aa8cb08e48590dbb3da7b08b1056828838c5f61e6393ba7a0abcc9f662898015ad"
let gcm15_T = "b094dac5d93471bdec1a502270e3cc6c"
let gcm16_K = "feffe9928665731c6d6a8f9467308308feffe9928665731c6d6a8f9467308308"
let gcm16_P = "d9313225f88406e5a55909c5aff5269a86a7a9531534f7da2e4c303d8a318a721c3c0c95956809532fcf0e2449a6b525b16aedf5aa0de657ba637b39"
let gcm16_A = "feedfacedeadbeeffeedfacedeadbeefabaddad2"
let gcm16_IV = "cafebabefacedbaddecaf888"
let gcm16_C = "522dc1f099567d07f47f37a32a84427d643a8cdcbfe5c0c97598a2bd2555d1aa8cb08e48590dbb3da7b08b1056828838c5f61e6393ba7a0abcc9f662"
let gcm16_T = "76fc6ece0f4e1768cddf8853bb2d551b"

// ---------------------------------------------------------------------------------------------------------------------------------
section("ChaCha20-Poly1305 (RFC 8439 section 2.8.2)")
attempt("ChaChaPoly") {
    let key = SymmetricKey(data: unhex(chacha_key))
    let nonce = try ChaChaPoly.Nonce(data: unhex(chacha_fixed + chacha_iv))
    let aad = unhex(chacha_aad)
    let plaintext = unhex(chacha_pt)

    let published = try ChaChaPoly.SealedBox(combined: unhex(chacha_fixed + chacha_iv + chacha_ct + chacha_tag))
    check(hex(published.ciphertext) == chacha_ct, "ChaChaPoly.SealedBox(combined:) splits the ciphertext")
    check(hex(published.tag) == chacha_tag, "ChaChaPoly.SealedBox(combined:) splits the tag")
    check(try ChaChaPoly.open(published, using: key, authenticating: aad) == plaintext, "ChaChaPoly.open of the published box gives the plaintext")

    let sealed = try ChaChaPoly.seal(plaintext, using: key, nonce: nonce, authenticating: aad)
    check(hex(sealed.ciphertext) == chacha_ct, "ChaChaPoly.seal gives the published ciphertext")
    check(hex(sealed.tag) == chacha_tag, "ChaChaPoly.seal gives the published tag")
    check(hex(sealed.combined) == chacha_fixed + chacha_iv + chacha_ct + chacha_tag, "ChaChaPoly.seal combined is nonce, ciphertext, tag")
    check(try ChaChaPoly.open(sealed, using: key, authenticating: aad) == plaintext, "ChaChaPoly seal then open round trip")

    let badTag = try ChaChaPoly.SealedBox(nonce: nonce, ciphertext: published.ciphertext, tag: flipped(published.tag))
    check(throwsError { _ = try ChaChaPoly.open(badTag, using: key, authenticating: aad) }, "ChaChaPoly.open throws on a flipped tag bit")
    let badCiphertext = try ChaChaPoly.SealedBox(nonce: nonce, ciphertext: flipped(published.ciphertext, bit: 5), tag: published.tag)
    check(throwsError { _ = try ChaChaPoly.open(badCiphertext, using: key, authenticating: aad) }, "ChaChaPoly.open throws on a flipped ciphertext bit")
    check(throwsError { _ = try ChaChaPoly.open(published, using: key, authenticating: flipped(aad)) }, "ChaChaPoly.open throws on different authenticated data")
    check(throwsError { _ = try ChaChaPoly.open(published, using: key) }, "ChaChaPoly.open throws when the authenticated data is missing")
    let wrongKey = SymmetricKey(data: unhex(chacha_key).reversed())
    check(throwsError { _ = try ChaChaPoly.open(published, using: wrongKey, authenticating: aad) }, "ChaChaPoly.open throws with the wrong key")
}

// ---------------------------------------------------------------------------------------------------------------------------------
section("AES-GCM (GCM specification test cases)")
struct GCMCase { let number: Int; let key: String; let plaintext: String; let aad: String; let iv: String; let ciphertext: String; let tag: String }
let gcmCases = [
    GCMCase(number: 1, key: gcm1_K, plaintext: gcm1_P, aad: "", iv: gcm1_IV, ciphertext: gcm1_C, tag: gcm1_T),
    GCMCase(number: 2, key: gcm2_K, plaintext: gcm2_P, aad: "", iv: gcm2_IV, ciphertext: gcm2_C, tag: gcm2_T),
    GCMCase(number: 3, key: gcm3_K, plaintext: gcm3_P, aad: "", iv: gcm3_IV, ciphertext: gcm3_C, tag: gcm3_T),
    GCMCase(number: 4, key: gcm4_K, plaintext: gcm4_P, aad: gcm4_A, iv: gcm4_IV, ciphertext: gcm4_C, tag: gcm4_T),
    GCMCase(number: 7, key: gcm7_K, plaintext: gcm7_P, aad: "", iv: gcm7_IV, ciphertext: gcm7_C, tag: gcm7_T),
    GCMCase(number: 8, key: gcm8_K, plaintext: gcm8_P, aad: "", iv: gcm8_IV, ciphertext: gcm8_C, tag: gcm8_T),
    GCMCase(number: 13, key: gcm13_K, plaintext: gcm13_P, aad: "", iv: gcm13_IV, ciphertext: gcm13_C, tag: gcm13_T),
    GCMCase(number: 14, key: gcm14_K, plaintext: gcm14_P, aad: "", iv: gcm14_IV, ciphertext: gcm14_C, tag: gcm14_T),
    GCMCase(number: 15, key: gcm15_K, plaintext: gcm15_P, aad: "", iv: gcm15_IV, ciphertext: gcm15_C, tag: gcm15_T),
    GCMCase(number: 16, key: gcm16_K, plaintext: gcm16_P, aad: gcm16_A, iv: gcm16_IV, ciphertext: gcm16_C, tag: gcm16_T),
]
for c in gcmCases {
    let name = "AES.GCM test case \(c.number) (\(c.key.count * 4)-bit key, \(c.plaintext.count / 2) byte plaintext, \(c.aad.count / 2) byte AAD)"
    attempt(name) {
        let key = SymmetricKey(data: unhex(c.key))
        let nonce = try AES.GCM.Nonce(data: unhex(c.iv))
        let aad = unhex(c.aad)
        let box = try AES.GCM.seal(unhex(c.plaintext), using: key, nonce: nonce, authenticating: aad)
        check(hex(box.ciphertext) == c.ciphertext, "\(name): seal ciphertext")
        check(hex(box.tag) == c.tag, "\(name): seal tag")
        let published = try AES.GCM.SealedBox(nonce: nonce, ciphertext: unhex(c.ciphertext), tag: unhex(c.tag))
        check(try AES.GCM.open(published, using: key, authenticating: aad) == unhex(c.plaintext), "\(name): open of the published box")
        let badTag = try AES.GCM.SealedBox(nonce: nonce, ciphertext: published.ciphertext, tag: flipped(published.tag, bit: 127))
        check(throwsError { _ = try AES.GCM.open(badTag, using: key, authenticating: aad) }, "\(name): open throws on a flipped tag bit")
        if !c.ciphertext.isEmpty {
            let badCiphertext = try AES.GCM.SealedBox(nonce: nonce, ciphertext: flipped(published.ciphertext, bit: 1), tag: published.tag)
            check(throwsError { _ = try AES.GCM.open(badCiphertext, using: key, authenticating: aad) }, "\(name): open throws on a flipped ciphertext bit")
        }
        if !aad.isEmpty {
            check(throwsError { _ = try AES.GCM.open(published, using: key, authenticating: flipped(aad)) }, "\(name): open throws on different authenticated data")
        }
    }
}
attempt("AES.GCM combined") {
    let key = SymmetricKey(data: unhex(gcm16_K))
    let box = try AES.GCM.seal(unhex(gcm16_P), using: key, nonce: AES.GCM.Nonce(data: unhex(gcm16_IV)), authenticating: unhex(gcm16_A))
    check(box.combined.map { hex($0) } == gcm16_IV + gcm16_C + gcm16_T, "AES.GCM combined of test case 16 is nonce, ciphertext, tag")
    let reparsed = try AES.GCM.SealedBox(combined: box.combined!)
    check(try AES.GCM.open(reparsed, using: key, authenticating: unhex(gcm16_A)) == unhex(gcm16_P), "AES.GCM.SealedBox(combined:) then open")
    let wrongKey = SymmetricKey(data: unhex(gcm16_K).reversed())
    check(throwsError { _ = try AES.GCM.open(reparsed, using: wrongKey, authenticating: unhex(gcm16_A)) }, "AES.GCM.open throws with the wrong key")
}

print(failures == 0 ? "PASS: cryptokit_kat_aead" : "FAIL: cryptokit_kat_aead, \(failures) checks failed")
if failures != 0 { exit(1) }
