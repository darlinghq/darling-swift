// NSRange's Swift extensions (Hashable, description, string parsing, bounds, set operations, Range and
// String.Index conversions, Codable) through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

let r = NSRange(location: 2, length: 3)
check(r.lowerBound == 2 && r.upperBound == 5, "lowerBound/upperBound")
check(r.contains(4) && !r.contains(5), "contains")
check(Set([r, NSRange(location: 2, length: 3), NSRange(location: 0, length: 1)]).count == 2, "Hashable")
check(r.description == "{2, 3}", "description (\(r.description))")
check(NSRange("{7, 4}") == NSRange(location: 7, length: 4) && NSRange("no digits") == nil, "init?(String)")
check(r.union(NSRange(location: 6, length: 2)) == NSRange(location: 2, length: 6), "union")
check(r.intersection(NSRange(location: 4, length: 10)) == NSRange(location: 4, length: 1)
      && r.intersection(NSRange(location: 9, length: 1)) == nil, "intersection")
check(NSRange(3..<8) == NSRange(location: 3, length: 5), "init(Range<Int>)")
let s = "h\u{e9}llo \u{1F600} world"
let emoji = s.range(of: "\u{1F600}")!
let ns = NSRange(emoji, in: s)
check(ns == NSRange(location: 6, length: 2), "init(_:in:) counts UTF-16 (\(ns))")
check(Range(ns, in: s) == emoji, "Range(_:in:) round trip")
let data = try! JSONEncoder().encode(r)
check((try? JSONDecoder().decode(NSRange.self, from: data)) == r, "Codable")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
if failures != 0 { exit(1) }
