// NSString literals and appendingFormat, NSCoder.decodeObject(of:forKey:) and URL.resourceValues(forKeys:) through the
// Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

// NSString literals: ASCII, non-ASCII (UTF-8) and a mutable subclass.
let ascii: NSString = "hello"
check(ascii.length() == 5 && (ascii as String) == "hello", "ASCII NSString literal")
let accented: NSString = "h\u{e9}llo \u{1F600}"
check((accented as String) == "h\u{e9}llo \u{1F600}" && accented.length() == 8, "non-ASCII NSString literal (length \(accented.length()))")
let empty: NSString = ""
check(empty.length() == 0, "empty NSString literal")
// A single-scalar literal arrives as a StaticString without a pointer representation.
let letter: NSString = "x"
check((letter as String) == "x" && letter.length() == 1, "single-scalar ASCII NSString literal (\(letter))")
let emoji: NSString = "\u{1F600}"
check((emoji as String) == "\u{1F600}" && emoji.length() == 2, "single-scalar non-BMP NSString literal (length \(emoji.length()))")
let mutable: NSMutableString = "abc"
mutable.append("d")
check((mutable as String) == "abcd", "NSMutableString literal stays mutable (\(mutable))")

// appendingFormat.
let formatted = ("id=" as NSString).appendingFormat("%d-%@", 42, "x" as NSString)
check((formatted as String) == "id=42-x", "appendingFormat (\(formatted))")
check((("a" as NSString).appendingFormat("") as String) == "a", "appendingFormat with an empty format")

// NSCoder.decodeObject(of:forKey:) on a keyed archive.
let data = NSMutableData(capacity: 0)!
let archiver = NSKeyedArchiver(forWritingWith: data)!
archiver.encode("value" as NSString, forKey: "name")
archiver.encode(7 as NSNumber, forKey: "number")
archiver.finishEncoding()
if let unarchiver = NSKeyedUnarchiver(forReadingWith: data) {
    let name: NSString? = unarchiver.decodeObject(of: NSString.self, forKey: "name")
    check(name == "value", "decodeObject(of: NSString.self)")
    let wrongClass: NSNumber? = unarchiver.decodeObject(of: NSNumber.self, forKey: "name")
    check(wrongClass == nil, "decodeObject(of:) with the wrong class gives nil")
    let number: NSNumber? = unarchiver.decodeObject(of: NSNumber.self, forKey: "number")
    check(number?.intValue() == 7, "decodeObject(of: NSNumber.self)")
    let missingName: NSString? = unarchiver.decodeObject(of: NSString.self, forKey: "missing")
    check(missingName == nil, "decodeObject(of:) for a missing key")
    let classes: [AnyClass]? = [NSString.self, NSNumber.self]
    let fromClasses: Any? = unarchiver.decodeObject(of: classes, forKey: "name")
    check(fromClasses as? String == "value", "decodeObject(of: [classes])")
    let fromNilClasses: Any? = unarchiver.decodeObject(of: nil as [AnyClass]?, forKey: "number")
    check(fromNilClasses as? Int == 7, "decodeObject(of: nil classes)")
    let missingFromClasses: Any? = unarchiver.decodeObject(of: [NSString.self] as [AnyClass]?, forKey: "missing")
    check(missingFromClasses == nil, "decodeObject(of: [classes]) for a missing key")
} else {
    check(false, "NSKeyedUnarchiver(forReadingWith:)")
}

// With secure coding on, Darling's unarchiver pushes the classes as the allowed set.
if let secure = NSKeyedUnarchiver(forReadingWith: data) {
    typealias SetBool = @convention(c) (AnyObject, Selector, Bool) -> Void
    let setter = Selector(("setRequiresSecureCoding:"))
    unsafeBitCast(secure.method(for: setter), to: SetBool.self)(secure, setter, true)
    check(secure.requiresSecureCoding(), "requiresSecureCoding is on")
    let secureName: Any? = secure.decodeObject(of: [NSString.self] as [AnyClass]?, forKey: "name")
    check(secureName as? String == "value", "decodeObject(of: [classes]) with secure coding")
} else {
    check(false, "NSKeyedUnarchiver(forReadingWith:) for secure coding")
}

// URL.resourceValues(forKeys:) and URLResourceValues.creationDate.
let creationKey = URLResourceKey(rawValue: NSURLCreationDateKey)
var template = Array((NSTemporaryDirectory() + "/console-resource.XXXXXX").utf8CString)
let fd = mkstemp(&template)
if fd >= 0 {
    close(fd)
    let path = String(cString: template)
    let before = Date(timeIntervalSinceNow: -120)
    do {
        let values = try URL(fileURLWithPath: path).resourceValues(forKeys: [creationKey])
        if let created = values.creationDate {
            check(created > before && created < Date(timeIntervalSinceNow: 120), "creationDate is recent (\(created))")
        } else {
            check(false, "creationDate is set")
        }
        let none = try URL(fileURLWithPath: path).resourceValues(forKeys: [])
        check(none.creationDate == nil, "creationDate is nil when not requested")
    } catch {
        check(false, "resourceValues(forKeys:) threw \(error)")
    }
    unlink(path)
    do {
        let missing = try URL(fileURLWithPath: path).resourceValues(forKeys: [creationKey])
        check(false, "resourceValues(forKeys:) for a missing file throws (got creationDate \(String(describing: missing.creationDate)))")
    } catch {
        check(true, "resourceValues(forKeys:) for a missing file throws (\(error))")
    }
} else {
    check(false, "mkstemp")
}

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
