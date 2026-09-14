// String.Encoding and the NSString-backed String/StringProtocol APIs through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

let text = "  Héllo, Wörld 🦀  "
let trimmed = text.trimmingCharacters(in: .whitespaces)
check(trimmed == "Héllo, Wörld 🦀", "trimmingCharacters(in:) (\(trimmed))")
check("a,b,,c".components(separatedBy: ",") == ["a", "b", "", "c"], "components(separatedBy: String)")
check("a b\tc".components(separatedBy: .whitespaces) == ["a", "b", "c"], "components(separatedBy: CharacterSet)")
check("one two one".replacingOccurrences(of: "one", with: "1") == "1 two 1", "replacingOccurrences")
check("Hello".replacingOccurrences(of: "l", with: "L", options: NSStringCompareOptions(rawValue: 0), range: nil) == "HeLLo", "replacingOccurrences with options")
check(trimmed.contains("Wörld") && !trimmed.contains("world") && !trimmed.contains(""), "contains")
check(trimmed.localizedCaseInsensitiveContains("wörld"), "localizedCaseInsensitiveContains")
check(trimmed.localizedStandardContains("world"), "localizedStandardContains (diacritic insensitive)")

// Ranges come back as indices into the receiver, including for substrings.
if let r = trimmed.range(of: "Wörld") {
    check(trimmed[r] == "Wörld", "range(of:) (\(trimmed[r]))")
} else { check(false, "range(of:)") }
let sub = trimmed.dropFirst(7)
if let r = sub.range(of: "ld") {
    check(sub[r] == "ld", "range(of:) on a Substring")
} else { check(false, "range(of:) on a Substring") }
if let r = trimmed.rangeOfCharacter(from: .decimalDigits) { check(false, "rangeOfCharacter unexpected \(r)") } else { check(true, "rangeOfCharacter none") }
if let r = "abc123".rangeOfCharacter(from: .decimalDigits) {
    check("abc123"[r] == "1", "rangeOfCharacter(from:)")
} else { check(false, "rangeOfCharacter(from:)") }

check("apple".caseInsensitiveCompare("APPLE") == .orderedSame, "caseInsensitiveCompare")
check("file2".localizedStandardCompare("file10") == .orderedAscending, "localizedStandardCompare (numeric)")
check("a".localizedCaseInsensitiveCompare("B") == .orderedAscending, "localizedCaseInsensitiveCompare")
check("abc".compare("abd") == .orderedAscending, "compare")
check("hello world".capitalized == "Hello World", "capitalized")
check("abc".uppercased(with: nil) == "ABC", "uppercased(with:)")
check("ab".padding(toLength: 5, withPad: "-", startingAt: 0) == "ab---", "padding")

// Darling's -enumerateSubstringsInRange: decodes the enumeration kind as bit flags (by words also matches by
// paragraphs), so compare with NSString directly and check that the ranges map back to the same substrings.
let sentence = "héllo wörld 🦀 end"
let byWords = NSStringEnumerationOptions(rawValue: 3)
var swiftPieces: [String] = []
var rangesMatch = true
sentence.enumerateSubstrings(in: sentence.index(sentence.startIndex, offsetBy: 1)..., options: byWords) { piece, range, _, _ in
    swiftPieces.append(piece ?? "")
    if piece.map({ sentence[range] != $0 }) ?? true { rangesMatch = false }
}
var objcPieces: [String] = []
let nsSentence = sentence as NSString
nsSentence.enumerateSubstrings(in: NSRange(location: 1, length: nsSentence.length() - 1), options: byWords) { piece, _, _, _ in
    objcPieces.append(piece ?? "")
}
check(!swiftPieces.isEmpty && swiftPieces == objcPieces, "enumerateSubstrings matches NSString (\(swiftPieces))")
check(rangesMatch, "enumerateSubstrings ranges index the receiver")
let tail = sentence.dropFirst(6)
var tailPieces: [String] = []
var tailRangesMatch = true
tail.enumerateSubstrings(in: tail.startIndex..., options: byWords) { piece, range, _, _ in
    tailPieces.append(piece ?? "")
    if piece.map({ tail[range] != $0 }) ?? true { tailRangesMatch = false }
}
check(!tailPieces.isEmpty && tailPieces.joined().hasPrefix("wörld") && tailRangesMatch,
      "enumerateSubstrings on a Substring (\(tailPieces))")
var stops = 0
sentence.enumerateSubstrings(in: sentence.startIndex..., options: NSStringEnumerationOptions(rawValue: 2 /* byComposedCharacterSequences */)) { _, _, _, stop in
    stops += 1
    stop = true
}
check(stops == 1, "enumerateSubstrings stop")

// Encodings and percent encoding
let data = "héllo".data(using: .utf8)!
check(data.count == 6, "data(using: .utf8)")
check(String(data: data, encoding: .utf8) == "héllo", "init(data:encoding:)")
check(String(data: Data([0xff, 0xfe]), encoding: .utf8) == nil, "invalid UTF-8 gives nil")
check("abc".data(using: .ascii)?.count == 3, "data(using: .ascii)")
check("a b/é".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) == "a%20b/%C3%A9", "addingPercentEncoding")
check("a%20b%2F%C3%A9".removingPercentEncoding == "a b/é", "removingPercentEncoding")
check("%zz".removingPercentEncoding == nil, "malformed percent encoding gives nil")
check("abc".cString(using: .utf8) == [97, 98, 99, 0], "cString(using:)")
check(String.Encoding.utf8.rawValue == 4 && String.Encoding.utf8 == .utf8, "String.Encoding")

let url = URL(fileURLWithPath: "/tmp/darling-swift-string-api.txt")
do {
    try "written by Swift".write(to: url, atomically: true, encoding: .utf8)
    check(String(data: try Data(contentsOf: url), encoding: .utf8) == "written by Swift", "write(to:atomically:encoding:)")
} catch {
    check(false, "write(to:atomically:encoding:) threw \(error)")
}

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
