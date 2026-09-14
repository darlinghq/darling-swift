// Exercises the ObjectiveC and CoreFoundation overlays without the Foundation Swift overlay:
// NSObject subclass + selectors, NSObject Equatable/Hashable, autoreleasepool, String -> NSString
// bridging through the stdlib, CF types as Hashable (_CFObject) and CGFloat.
import ObjectiveC
import CoreFoundation

final class Counter: NSObject {
    var count = 0
    @objc func bump() { count += 1 }
}

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

let counter = Counter()
let bump = Selector("bump")
check(counter.responds(to: bump), "responds(to: Selector(\"bump\"))")
_ = counter.perform(bump)
_ = counter.perform(#selector(Counter.bump))
check(counter.count == 2, "perform(selector) ran twice (count=\(counter.count))")
check(bump == #selector(Counter.bump), "Selector ==")
check(Set([bump, #selector(Counter.bump)]).count == 1, "Selector Hashable")

let other = Counter()
check(counter == counter && counter != other, "NSObject ==")
check(Set<NSObject>([counter, other, counter]).count == 2, "NSObject Hashable")
check(String(cString: class_getName(Counter.self)).hasSuffix("Counter"), "class name \(String(cString: class_getName(Counter.self)))")

autoreleasepool {
    let boxed = "héllo darling" as AnyObject
    check((boxed as? String) == "héllo darling", "boxed String round-trips")
}

// CF <-> Swift String through the C API (toll-free bridging to NSString needs the Foundation overlay).
let cfFromSwift = CFStringCreateWithCString(nil, "héllo", CFStringBuiltInEncodings.UTF8.rawValue)!
check(CFStringGetLength(cfFromSwift) == 5, "CFString from Swift String (UTF-16 length 5)")
var buffer = [CChar](repeating: 0, count: 32)
check(CFStringGetCString(cfFromSwift, &buffer, 32, CFStringBuiltInEncodings.UTF8.rawValue), "CFStringGetCString")
check(String(cString: buffer) == "héllo", "CFString back to Swift String")

let a = CFStringCreateWithCString(nil, "darling", CFStringBuiltInEncodings.UTF8.rawValue)!
let b = CFStringCreateWithCString(nil, "darling", CFStringBuiltInEncodings.UTF8.rawValue)!
check(CFStringGetLength(a) == 7, "CFStringGetLength")
check(a == b, "CFString == (_CFObject)")
check(Set([a, b]).count == 1, "CFString Hashable (_CFObject)")

let width: CGFloat = 1.5
check(width * 2 == 3, "CGFloat arithmetic")
check((width * width).squareRoot() == width, "CGFloat squareRoot")
check(CGFloat.pi > 3.14 && CGFloat.pi < 3.15, "CGFloat.pi")
check(MemoryLayout<CGFloat>.size == 8, "CGFloat is 64-bit")
check("\(width)" == "1.5", "CGFloat description")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
