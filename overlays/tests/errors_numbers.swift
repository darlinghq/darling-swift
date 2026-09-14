// Error <-> NSError bridging, NSNumber bridging, String(format:), NSLocalizedString, NSNotFound and
// Range(NSRange, in:) through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

enum ProbeError: Error, LocalizedError {
    case broken
    var errorDescription: String? { "the probe is broken" }
}

struct CodedError: Error, CustomNSError {
    static var errorDomain: String { "org.darling.probe" }
    var errorCode: Int { 42 }
    var errorUserInfo: [String: Any] { ["detail": "custom"] }
}

// A bridged stored NSError, like CocoaError.
struct ProbeStoredError: _BridgedStoredNSError {
    struct Code: RawRepresentable, _ErrorCodeProtocol, Hashable {
        typealias _ErrorType = ProbeStoredError
        let rawValue: Int
    }
    static var errorDomain: String { "org.darling.stored" }
    let _nsError: NSError
    init(_nsError error: NSError) { _nsError = error }
}

// Error -> NSError
let probe: Error = ProbeError.broken
let nsProbe = probe as NSError
check(nsProbe.localizedDescription() == "the probe is broken", "LocalizedError description reaches NSError (\(nsProbe.localizedDescription()))")
check(probe.localizedDescription == "the probe is broken", "Error.localizedDescription")
let coded = CodedError() as NSError
check(coded.domain() == "org.darling.probe" && coded.code() == 42, "CustomNSError domain and code")
check((coded.userInfo()?["detail"] as? String) == "custom", "CustomNSError user info")

// NSError -> Error
let objcError = NSError(domain: "org.darling.stored", code: 7, userInfo: nil)!
let asError: Error = objcError
check((asError as NSError) === objcError, "NSError as Error keeps identity")
check(asError._domain == "org.darling.stored" && asError._code == 7, "NSError _domain/_code")
if let stored = asError as? ProbeStoredError {
    check(stored.code.rawValue == 7, "NSError casts to a _BridgedStoredNSError")
} else {
    check(false, "NSError casts to a _BridgedStoredNSError")
}
check((NSError(domain: "other", code: 1, userInfo: nil)! as Error as? ProbeStoredError) == nil, "wrong domain doesn't bridge")
let nilError = _convertNSErrorToError(nil)
check(String(describing: nilError).contains("nilError"), "nil NSError converts to a placeholder error")

// Throwing across an NSError
func throwsCoded() throws { throw CodedError() }
do { try throwsCoded() } catch let error as NSError {
    check(error.code() == 42, "catch as NSError")
}

// NSNumber
let n: NSNumber = 5
check(n.integerValue() == 5, "NSNumber integer literal")
check((true as NSNumber).boolValue(), "NSNumber boolean literal")
check((2.5 as NSNumber).doubleValue() == 2.5, "NSNumber float literal")
check((42 as NSNumber) as? Int == 42, "NSNumber as? Int")
check((NSNumber(integer: 1) as? Bool) == true, "NSNumber(1) as? Bool")
check((NSNumber(integer: 7) as? Bool) == nil, "NSNumber(7) as? Bool fails")
let anyNumbers = [1, 2, 3] as NSArray
check((anyNumbers as? [Int]) == [1, 2, 3], "[Int] through NSArray uses Int bridging")
check((Int64(1) << 40) as NSNumber == NSNumber(longLong: 1 << 40), "Int64 bridging")
// NSNumber Booleans hash like Bool, not like Int64(1) and Int64(0).
check((true as NSNumber as AnyHashable) == AnyHashable(true), "@YES as AnyHashable == AnyHashable(true)")
check((NSNumber(bool: false)! as AnyHashable) == AnyHashable(false), "@NO as AnyHashable == AnyHashable(false)")
check((NSNumber(integer: 1) as AnyHashable) == AnyHashable(Int64(1)) && (NSNumber(integer: 1) as AnyHashable) != AnyHashable(true),
      "NSNumber(1) as AnyHashable is still an integer, not a Boolean")
let boolKeyed = NSMutableDictionary()
boolKeyed.setObject("yes", forKey: NSNumber(bool: true)!)
check(((boolKeyed as! [AnyHashable: Any])[true] as? String) == "yes", "NSDictionary with a Boolean key bridges to [AnyHashable: Any] found by true")

// Formatting and localization
check(String(format: "%@ has %d items", "list", 3) == "list has 3 items", "String(format:) with String and Int")
check(String.localizedStringWithFormat("%d-%@", 9, "x") == "9-x", "localizedStringWithFormat")
check(NSLocalizedString("untranslated-key", comment: "") == "untranslated-key", "NSLocalizedString falls back to the key")
check(NSNotFound == Int.max, "NSNotFound")

// Range(NSRange, in:)
let text = "Héllo, wörld"
let nsRange = NSRange(location: 7, length: 5)
if let r = Range(nsRange, in: text) {
    check(text[r] == "wörld", "Range(NSRange, in:) (\(text[r]))")
} else {
    check(false, "Range(NSRange, in:)")
}
check(Range(NSRange(location: NSNotFound, length: 0), in: text) == nil, "NSNotFound range converts to nil")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
