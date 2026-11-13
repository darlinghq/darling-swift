// Foundation.AffineTransform and its NSAffineTransform bridge, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

let scale = AffineTransform(scale: 2)
let scaled = scale.transform(NSPoint(x: 3, y: 4))
check(scaled.x == 6 && scaled.y == 8, "init(scale:) transforms a point")
var t = AffineTransform(translationByX: 10, byY: 0)
t.rotate(byDegrees: 90)
let p = t.transform(NSPoint(x: 1, y: 0))
check(abs(p.x - 10) < 1e-9 && abs(p.y - 1) < 1e-9, "translate then rotate (\(p))")
check(t.inverted().map { $0.transform(p) }.map { abs($0.x - 1) < 1e-9 && abs($0.y) < 1e-9 } == true, "inverted")
check(AffineTransform(scale: 0).inverted() == nil, "singular matrix has no inverse")

let ns = t as NSAffineTransform
let nsPoint = ns.transform(NSPoint(x: 1, y: 0))
check(abs(nsPoint.x - p.x) < 1e-9 && abs(nsPoint.y - p.y) < 1e-9, "bridged NSAffineTransform agrees (\(nsPoint))")
check((ns as AffineTransform) == t, "bridge round trip")
let data = try! JSONEncoder().encode(scale)
check((try? JSONDecoder().decode(AffineTransform.self, from: data)) == scale, "Codable")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
if failures != 0 { exit(1) }
