// NSKeyedUnarchiver.unarchivedObject(ofClass:from:) / (ofClasses:from:), the generic overlay
// over darling-foundation's NS_REFINED_FOR_SWIFT unarchivedObjectOfClass(es):fromData:error:.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

let original = NSNumber(value: 42)
let data = NSKeyedArchiver.archivedData(withRootObject: original)!

// This is the exact call shape OpenSwiftUI's AccessibilityNumber.swift uses.
let decoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSNumber.self, from: data)
check(decoded == original, "unarchivedObject(ofClass:from:) round-trips and keeps its static type")

let decodedAny = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSNumber.self], from: data)
check((decodedAny as? NSNumber) == original, "unarchivedObject(ofClasses:from:) round-trips")

do {
    _ = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSNumber.self, from: Data([0xFF, 0x00, 0x01]))
    check(false, "decoding garbage data should throw, not return")
} catch {
    check(true, "decoding garbage data throws (\(error))")
}

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
if failures != 0 { exit(1) }
