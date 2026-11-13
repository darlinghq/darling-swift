// CGPoint and CGRect Codable from the CoreGraphics overlay, under Darling.
import CoreGraphics
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

let encoder = JSONEncoder()
let decoder = JSONDecoder()
let rect = CGRect(x: 1, y: 2, width: 3, height: 4)
let json = String(data: try! encoder.encode(rect), encoding: .utf8)
check(json == "[[1,2],[3,4]]", "a rect encodes as [origin, size]: \(json ?? "nil")")
check(try! decoder.decode(CGRect.self, from: Data("[[1,2],[3,4]]".utf8)) == rect, "a rect decodes")
check(String(data: try! encoder.encode(CGPoint(x: 5, y: 6)), encoding: .utf8) == "[5,6]", "a point encodes as [x, y]")
check(try! decoder.decode(CGPoint.self, from: Data("[5,6]".utf8)) == CGPoint(x: 5, y: 6), "a point decodes")
check((try? decoder.decode(CGRect.self, from: Data("[[1,2]]".utf8))) == nil, "a short rect is rejected")
check((try? decoder.decode(CGPoint.self, from: Data("[5]".utf8))) == nil, "a short point is rejected")

if failures != 0 { exit(1) }
