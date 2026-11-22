// CryptoKit.framework under Darling: that it loads and that SHA-256 and HMAC-SHA-256 give the values the standards
// publish. Uses only API that Apple documents for CryptoKit.
//
// Vectors (each was also computed with the host's sha256sum and openssl, see the commit that adds this file):
//   - SHA-256 of "abc" and of the empty string: the examples of NIST FIPS 180-4
//     (https://csrc.nist.gov/pubs/fips/180-4/upd1/final) and the NIST example values page
//     (https://csrc.nist.gov/projects/cryptographic-standards-and-guidelines/example-values).
//   - HMAC-SHA-256, key "Jefe", data "what do ya want for nothing?": test case 2 of RFC 4231, section 4.3
//     (https://www.rfc-editor.org/rfc/rfc4231#section-4.3).
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

let sha256Abc = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
let sha256Empty = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
let hmacCase2 = "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843"

// SHA-256, one shot
check(hex(SHA256.hash(data: Data("abc".utf8))) == sha256Abc, "SHA256.hash of \"abc\" (FIPS 180-4)")
check(hex(SHA256.hash(data: Data())) == sha256Empty, "SHA256.hash of the empty message (FIPS 180-4)")
check(hex(SHA256.hash(data: Data("abd".utf8))) != sha256Abc, "SHA256.hash of a different message differs")

// SHA-256, incremental: the split of the input must not matter
var hasher = SHA256()
hasher.update(data: Data("a".utf8))
hasher.update(data: Data("bc".utf8))
check(hex(hasher.finalize()) == sha256Abc, "SHA256 update in two parts, then finalize")

let emptyHasher = SHA256()
check(hex(emptyHasher.finalize()) == sha256Empty, "SHA256 finalize with no update")

var emptyUpdate = SHA256()
emptyUpdate.update(data: Data())
emptyUpdate.update(data: Data("abc".utf8))
check(hex(emptyUpdate.finalize()) == sha256Abc, "SHA256 update with an empty Data changes nothing")

// HMAC-SHA-256 (RFC 4231 test case 2)
let key = SymmetricKey(data: Data("Jefe".utf8))
let message = Data("what do ya want for nothing?".utf8)
check(hex(HMAC<SHA256>.authenticationCode(for: message, using: key)) == hmacCase2,
      "HMAC<SHA256> key \"Jefe\" (RFC 4231 test case 2)")
let otherKey = SymmetricKey(data: Data("Jefd".utf8))
check(hex(HMAC<SHA256>.authenticationCode(for: message, using: otherKey)) != hmacCase2,
      "HMAC<SHA256> with a different key differs")
check(hex(HMAC<SHA256>.authenticationCode(for: Data("what do ya want for nothing!".utf8), using: key)) != hmacCase2,
      "HMAC<SHA256> of a different message differs")

print(failures == 0 ? "PASS: cryptokit_smoke" : "FAIL: cryptokit_smoke, \(failures) checks failed")
if failures != 0 { exit(1) }
