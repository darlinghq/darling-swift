// Exercises only the ObjectiveC overlay: NSObject subclass, selectors, NSObject Equatable/Hashable,
// autoreleasepool, ObjCBool and String -> NSString bridging through the stdlib.
import ObjectiveC

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
check(bump.description == "bump", "Selector description")

let other = Counter()
check(counter == counter && counter != other, "NSObject ==")
check(Set<NSObject>([counter, other, counter]).count == 2, "NSObject Hashable")
check(String(cString: class_getName(Counter.self)).hasSuffix("Counter"), "class_getName \(String(cString: class_getName(Counter.self)))")

let yes: ObjCBool = true
check(yes.boolValue && !ObjCBool(false).boolValue, "ObjCBool")

// Without the Foundation Swift overlay String has no _ObjectiveCBridgeable conformance, so it is boxed
// (__SwiftValue); check that the box round-trips through the ObjC runtime inside an autoreleasepool.
autoreleasepool {
    let boxed = "héllo darling" as AnyObject
    check(String(cString: object_getClassName(boxed)).contains("SwiftValue"), "String boxed as \(String(cString: object_getClassName(boxed)))")
    check((boxed as? String) == "héllo darling", "boxed String round-trips")
    check(String(cString: sel_getName(bump)) == "bump", "sel_getName")
}

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
