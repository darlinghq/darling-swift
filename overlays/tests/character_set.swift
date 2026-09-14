// CharacterSet through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

func scalar(_ s: String) -> Unicode.Scalar { return s.unicodeScalars.first! }

// Predefined sets
check(CharacterSet.whitespaces.contains(" ") && !CharacterSet.whitespaces.contains("\n"), "whitespaces")
check(CharacterSet.whitespacesAndNewlines.contains("\n") && CharacterSet.whitespacesAndNewlines.contains("\t"), "whitespacesAndNewlines")
check(CharacterSet.newlines.contains("\r") && !CharacterSet.newlines.contains(" "), "newlines")
check(CharacterSet.alphanumerics.contains("a") && CharacterSet.alphanumerics.contains("7") && !CharacterSet.alphanumerics.contains("-"), "alphanumerics")
check(CharacterSet.decimalDigits.contains("5") && !CharacterSet.decimalDigits.contains("x"), "decimalDigits")
check(CharacterSet.punctuationCharacters.contains("!") && !CharacterSet.punctuationCharacters.contains("a"), "punctuationCharacters")
check(CharacterSet.controlCharacters.contains(scalar("\u{7}")), "controlCharacters")

// URL allowed sets (RFC 3986 classes, as on macOS)
check(CharacterSet.urlPathAllowed.contains("/") && !CharacterSet.urlPathAllowed.contains("?") && !CharacterSet.urlPathAllowed.contains(" "), "urlPathAllowed")
check(CharacterSet.urlQueryAllowed.contains("?") && CharacterSet.urlQueryAllowed.contains("=") && !CharacterSet.urlQueryAllowed.contains("#"), "urlQueryAllowed")
check(CharacterSet.urlFragmentAllowed.contains("/") && !CharacterSet.urlFragmentAllowed.contains("#"), "urlFragmentAllowed")
check(CharacterSet.urlHostAllowed.contains(":") && !CharacterSet.urlHostAllowed.contains("/"), "urlHostAllowed")
check(!CharacterSet.urlUserAllowed.contains(":") && !CharacterSet.urlUserAllowed.contains("@"), "urlUserAllowed")
check(CharacterSet.urlPasswordAllowed.contains("!") && !CharacterSet.urlPasswordAllowed.contains("@"), "urlPasswordAllowed")

// Building and set algebra
var custom = CharacterSet(charactersIn: "abc")
check(custom.contains("b") && !custom.contains("d"), "init(charactersIn:)")
custom.insert(charactersIn: "xyz")
check(custom.contains("y"), "insert(charactersIn:)")
let inserted = custom.insert("é")
check(inserted.inserted && custom.contains("é"), "insert(_:)")
let union = custom.union(.decimalDigits)
check(union.contains("9") && union.contains("a"), "union")
check(union.isSuperset(of: custom), "isSuperset(of:)")
check(!CharacterSet.alphanumerics.inverted.contains("a") && CharacterSet.alphanumerics.inverted.contains("-"), "inverted")
check(CharacterSet().isEmpty && !custom.isEmpty, "empty set")
check(custom.subtracting(CharacterSet(charactersIn: "abc")).contains("x") && !custom.subtracting(CharacterSet(charactersIn: "abc")).contains("a"), "subtracting")

// Bridging and value semantics
let ns = custom as NSCharacterSet
check(ns.longCharacterIsMember(UInt32(UInt8(ascii: "a"))), "CharacterSet bridges to NSCharacterSet")
let back = CharacterSet._unconditionallyBridgeFromObjectiveC(NSCharacterSet.whitespaceCharacterSet() as? NSCharacterSet)
check(back.contains(" "), "NSCharacterSet bridges back")
var copy = custom
copy.remove("a")
check(custom.contains("a") && !copy.contains("a"), "value semantics")
check(Set([CharacterSet.whitespaces, CharacterSet.whitespaces]).count == 1, "Hashable")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
