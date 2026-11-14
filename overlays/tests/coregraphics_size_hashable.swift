// CGSize: Hashable through the CoreGraphics overlay.
import CoreGraphics

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

let a = CGSize(width: 3, height: 4)
check(a == CGSize(width: 3, height: 4) && a.hashValue == CGSize(width: 3, height: 4).hashValue, "equal sizes hash equally")
check(CGSize(width: 0, height: 1).hashValue == CGSize(width: -0.0, height: 1).hashValue, "-0 and +0 widths hash equally")
check(Set([a, CGSize(width: 3, height: 4), CGSize(width: 4, height: 3), .zero]).count == 3, "Set dedupes equal sizes")
var counts: [CGSize: Int] = [:]
counts[a, default: 0] += 1
counts[CGSize(width: 3, height: 4), default: 0] += 1
check(counts[a] == 2 && counts.count == 1, "CGSize as a dictionary key")

print(failures == 0 ? "ALL PASS" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
