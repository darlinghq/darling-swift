// CryptoKit.framework under Darling: known-answer tests for the hash and key-derivation primitives behind BoringSSL and XKCP: SHA-1, SHA-384,
// SHA-512, SHA3-256, HMAC-SHA-256/384/512 and HKDF-SHA-256, plus SymmetricKey comparison.
//
// Vector groups and their sources:
//   - SHA-1, SHA-384, SHA-512 of "abc" and of the two block message: NIST example values for FIPS 180-4
//     (https://csrc.nist.gov/projects/cryptographic-standards-and-guidelines/example-values : SHA1.pdf, SHA384.pdf, SHA512.pdf).
//   - SHA3-256 of the 0-bit and the 1600-bit message: NIST example values for FIPS 202 (same page: SHA3-256_Msg0.pdf, SHA3-256_1600.pdf).
//     SHA3-256 of "abc" is not covered: neither FIPS 202 nor those example files give it.
//   - HMAC-SHA-256/384/512, key "Jefe": RFC 4231 section 4.3, test case 2 (https://www.rfc-editor.org/rfc/rfc4231#section-4.3).
//   - HKDF-SHA-256: RFC 5869 appendix A.1, test case 1 (https://www.rfc-editor.org/rfc/rfc5869#appendix-A.1).
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

func section(_ name: String) { print("--- \(name)") }

// NIST example values, SHA-1 / SHA-384 / SHA-512: one block message "abc" and two block message (FIPS 180-4 examples,
// https://csrc.nist.gov/projects/cryptographic-standards-and-guidelines/example-values : SHA1.pdf, SHA384.pdf, SHA512.pdf).
let sha1_abc = "a9993e364706816aba3e25717850c26c9cd0d89d"
let sha1_two_block = "84983e441c3bd26ebaae4aa1f95129e5e54670f1"
let sha1_two_block_msg = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
let sha384_abc = "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7"
let sha384_two_block = "09330c33f71147e83d192fc782cd1b4753111b173b3b05d22fa08086e3b0f712fcc7c71a557e2db966c3e9fa91746039"
let sha384_two_block_msg = "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"
let sha512_abc = "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f"
let sha512_two_block = "8e959b75dae313da8cf4f72814fc143f8f7779c6eb9f7fa17299aeadb6889018501d289e4900f7e4331b99dec4b5433ac7d329eeb6dd26545e96e55b874be909"
let sha512_two_block_msg = "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"

// NIST example values, SHA3-256 (FIPS 202 examples, same page: SHA3-256_Msg0.pdf, SHA3-256_1600.pdf; the 1600-bit message is 200 bytes of 0xA3,
// the bit string 1 1 0 0 0 1 0 1 repeated, least significant bit first).
let sha3_256_empty = "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a"
let sha3_256_1600 = "79f38adec5c20307a98ef76e8324afbfd46cfd81b22e3973c65fa1bd9de31787"

// RFC 4231 section 4.3, test case 2 (HMAC-SHA-256/384/512, key "Jefe").
let hmac_tc2_key = "4a656665"
let hmac_tc2_data = "7768617420646f2079612077616e7420666f72206e6f7468696e673f"
let hmac256_tc2 = "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843"
let hmac384_tc2 = "af45d2e376484031617f78d2b58a6b1b9c7ef464f5a01b47e42ec3736322445e8e2240ca5e69e2c78b3239ecfab21649"
let hmac512_tc2 = "164b7a7bfcf819e2e395fbe73b56e0a387bd64222e831fd610270cd7ea2505549758bf75c05a994a6d034f65f8f0e6fdcaeab1a34d4a6b4b636e070a38bce737"

// RFC 5869 appendix A.1, test case 1 (HKDF with SHA-256).
let hkdf_IKM = "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b"
let hkdf_salt = "000102030405060708090a0b0c"
let hkdf_info = "f0f1f2f3f4f5f6f7f8f9"
let hkdf_PRK = "077709362c2e32df0ddc3f0dc47bba6390b6c73bb50f9c3122ec844ad7c2b3e5"
let hkdf_OKM = "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865"

// ---------------------------------------------------------------------------------------------------------------------------------
section("SHA-1, SHA-384, SHA-512, SHA3-256")
let abc = Data("abc".utf8)
check(hex(Insecure.SHA1.hash(data: abc)) == sha1_abc, "Insecure.SHA1 of \"abc\" (NIST example)")
check(hex(SHA384.hash(data: abc)) == sha384_abc, "SHA384 of \"abc\" (FIPS 180-4 example)")
check(hex(SHA512.hash(data: abc)) == sha512_abc, "SHA512 of \"abc\" (FIPS 180-4 example)")
check(hex(Insecure.SHA1.hash(data: Data(sha1_two_block_msg.utf8))) == sha1_two_block, "Insecure.SHA1 two block message (NIST example)")
check(hex(SHA384.hash(data: Data(sha384_two_block_msg.utf8))) == sha384_two_block, "SHA384 two block message (NIST example)")
check(hex(SHA512.hash(data: Data(sha512_two_block_msg.utf8))) == sha512_two_block, "SHA512 two block message (NIST example)")
check(hex(SHA3_256.hash(data: Data())) == sha3_256_empty, "SHA3_256 of the empty message (FIPS 202 example)")
check(hex(SHA3_256.hash(data: Data(repeating: 0xA3, count: 200))) == sha3_256_1600, "SHA3_256 of the 1600-bit message (FIPS 202 example)")

// the split of the input must not matter
var sha384Hasher = SHA384()
sha384Hasher.update(data: Data("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnop".utf8))
sha384Hasher.update(data: Data("jklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu".utf8))
check(hex(sha384Hasher.finalize()) == sha384_two_block, "SHA384 incremental, two parts")
var sha512Hasher = SHA512()
for byte in sha512_two_block_msg.utf8 { sha512Hasher.update(data: Data([byte])) }
check(hex(sha512Hasher.finalize()) == sha512_two_block, "SHA512 incremental, one byte at a time")
var sha3Hasher = SHA3_256()
for _ in 0..<4 { sha3Hasher.update(data: Data(repeating: 0xA3, count: 50)) }
check(hex(sha3Hasher.finalize()) == sha3_256_1600, "SHA3_256 incremental, 4 x 50 bytes")
var sha1Hasher = Insecure.SHA1()
sha1Hasher.update(data: Data("a".utf8))
sha1Hasher.update(data: Data("bc".utf8))
check(hex(sha1Hasher.finalize()) == sha1_abc, "Insecure.SHA1 incremental, \"a\" then \"bc\"")

// ---------------------------------------------------------------------------------------------------------------------------------
section("HMAC-SHA-384, HMAC-SHA-512")
let hmacKey = SymmetricKey(data: unhex(hmac_tc2_key))
let hmacData = unhex(hmac_tc2_data)
check(hex(HMAC<SHA256>.authenticationCode(for: hmacData, using: hmacKey)) == hmac256_tc2, "HMAC<SHA256> RFC 4231 test case 2")
check(hex(HMAC<SHA384>.authenticationCode(for: hmacData, using: hmacKey)) == hmac384_tc2, "HMAC<SHA384> RFC 4231 test case 2")
check(hex(HMAC<SHA512>.authenticationCode(for: hmacData, using: hmacKey)) == hmac512_tc2, "HMAC<SHA512> RFC 4231 test case 2")
check(HMAC<SHA512>.isValidAuthenticationCode(unhex(hmac512_tc2), authenticating: hmacData, using: hmacKey), "HMAC<SHA512>.isValidAuthenticationCode accepts the published code")
check(!HMAC<SHA512>.isValidAuthenticationCode(flipped(unhex(hmac512_tc2)), authenticating: hmacData, using: hmacKey), "HMAC<SHA512>.isValidAuthenticationCode rejects a code with a flipped bit")

// ---------------------------------------------------------------------------------------------------------------------------------
section("HKDF-SHA-256 (RFC 5869 test case 1)")
let ikm = SymmetricKey(data: unhex(hkdf_IKM))
let prk = HKDF<SHA256>.extract(inputKeyMaterial: ikm, salt: unhex(hkdf_salt))
check(hex(prk) == hkdf_PRK, "HKDF<SHA256>.extract gives the published PRK")
let okmFromExpand = HKDF<SHA256>.expand(pseudoRandomKey: prk, info: unhex(hkdf_info), outputByteCount: 42)
check(okmFromExpand.withUnsafeBytes { hex($0) } == hkdf_OKM, "HKDF<SHA256>.expand gives the published OKM")
let okmFromDerive = HKDF<SHA256>.deriveKey(inputKeyMaterial: ikm, salt: unhex(hkdf_salt), info: unhex(hkdf_info), outputByteCount: 42)
check(okmFromDerive.withUnsafeBytes { hex($0) } == hkdf_OKM, "HKDF<SHA256>.deriveKey gives the published OKM")
check(okmFromDerive.bitCount == 42 * 8, "HKDF<SHA256>.deriveKey output has 42 bytes")
let okmOtherInfo = HKDF<SHA256>.deriveKey(inputKeyMaterial: ikm, salt: unhex(hkdf_salt), info: Data("other".utf8), outputByteCount: 42)
check(okmOtherInfo.withUnsafeBytes { hex($0) } != hkdf_OKM, "HKDF<SHA256>.deriveKey with different info differs")

// ---------------------------------------------------------------------------------------------------------------------------------
section("SymmetricKey comparison")
let keyA = SymmetricKey(data: unhex("000102030405060708090a0b0c0d0e0f"))
let keyACopy = SymmetricKey(data: unhex("000102030405060708090a0b0c0d0e0f"))
let keyB = SymmetricKey(data: unhex("000102030405060708090a0b0c0d0e0e"))
let keyLonger = SymmetricKey(data: unhex("000102030405060708090a0b0c0d0e0f10"))
check(keyA == keyACopy, "SymmetricKey == for equal bytes")
check(!(keyA == keyB), "SymmetricKey == for bytes that differ in the last bit")
check(!(keyA == keyLonger), "SymmetricKey == for keys of different sizes")
check(keyA.bitCount == 128 && keyLonger.bitCount == 136, "SymmetricKey.bitCount")
check(SymmetricKey(size: .bits128).bitCount == 128 && SymmetricKey(size: .bits192).bitCount == 192 && SymmetricKey(size: .bits256).bitCount == 256,
      "SymmetricKey(size:) bit counts")

print(failures == 0 ? "PASS: cryptokit_kat_hash" : "FAIL: cryptokit_kat_hash, \(failures) checks failed")
if failures != 0 { exit(1) }
