// String <-> NSString bridging through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

let swiftString = "Héllo, Darling 🦀"
let ns = swiftString as NSString
check(ns.length() == swiftString.utf16.count, "String as NSString keeps UTF-16 length (\(ns.length()))")
let back = ns as String
check(back == swiftString, "NSString as String round-trips")
let upper: String = ns.uppercase()
check(upper == swiftString.uppercased(), "NSString method result imported as String (\(upper))")
// Darling's headers have no nullability, so initializers import as returning optionals.
let created = NSString(string: "passed to ObjC as String")!
check((created as String) == "passed to ObjC as String", "String argument bridged into -initWithString:")
let fromCString = NSString(utf8String: "created in ObjC")!
check((fromCString as String) == "created in ObjC", "NSString created by Foundation bridges to String")
let object: AnyObject = swiftString as NSString
check((object as? String) == swiftString, "AnyObject holding an NSString casts to String")
check(object.isKind(of: NSString.self), "bridged object is an NSString")
check(("abc" as NSString).isEqual(to: "abc"), "-isEqualToString: with a bridged argument")
print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
