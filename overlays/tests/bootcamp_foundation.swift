// NSFastEnumeration iteration, NSPredicate(format:), NSDictionary literals, CocoaError and
// FileManager.enumerator(at:...) through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

// Fast enumeration: more than 16 elements, so the iterator refills its buffer.
let numbers = Array(0..<40) as NSArray
var seen: [Int] = []
for element in numbers { seen.append(element as! Int) }
check(seen == Array(0..<40), "for-in over NSArray (\(seen.count) elements)")
var fromEnumerator: [Int] = []
for element in numbers.objectEnumerator() { fromEnumerator.append(element as! Int) }
check(fromEnumerator == Array(0..<40), "for-in over NSEnumerator")
var emptyCount = 0
for _ in ([] as NSArray) { emptyCount += 1 }
check(emptyCount == 0, "for-in over an empty NSArray")

// Dictionary literals, and enumerating keys through NSEnumerator.
let literal: NSDictionary = ["one": 1, "two": "zwei", 3: [1, 2]]
check(literal.count() == 3, "NSDictionary literal count")
check(literal.object(forKey: "one") as? Int == 1 && literal.object(forKey: "two") as? String == "zwei"
      && literal.object(forKey: 3) as? [Int] == [1, 2], "NSDictionary literal values")
var keys: [String] = []
for key in literal.keyEnumerator() { keys.append("\(key)") }
check(Set(keys) == ["one", "two", "3"], "for-in over keyEnumerator (\(keys))")
let emptyLiteral: NSDictionary = [:]
check(emptyLiteral.count() == 0, "empty NSDictionary literal")
let mutableLiteral: NSMutableDictionary = ["a": 1]
mutableLiteral.setObject(2, forKey: "b" as NSString)
check(mutableLiteral.count() == 2 && mutableLiteral.object(forKey: "a") as? Int == 1
      && mutableLiteral.object(forKey: "b") as? Int == 2, "NSMutableDictionary literal stays mutable")

// NSPredicate(format:) with variadic arguments.
check(NSPredicate(format: "SELF > %d", 5).evaluate(with: 7), "predicate with %d matches")
check(!NSPredicate(format: "SELF > %d", 5).evaluate(with: 3), "predicate with %d rejects")
check(NSPredicate(format: "name == %@ AND capacity < %d", "disk", 10).evaluate(with: ["name": "disk", "capacity": 4] as NSDictionary),
      "predicate with %@ and %d against a dictionary")
check(NSPredicate(format: "TRUEPREDICATE").evaluate(with: nil), "predicate without arguments")

// CocoaError.
let exists = NSError(domain: NSCocoaErrorDomain, code: 516, userInfo: nil)! as Error
check(CocoaError.fileWriteFileExists.rawValue == 516 && CocoaError.Code.fileWriteFileExists == CocoaError.fileWriteFileExists,
      "CocoaError.fileWriteFileExists")
do {
    throw exists
} catch CocoaError.fileWriteFileExists {
    check(true, "catch CocoaError.fileWriteFileExists")
} catch {
    check(false, "catch CocoaError.fileWriteFileExists (got \(error))")
}
check((exists as? CocoaError)?.code == .fileWriteFileExists, "NSError as? CocoaError")
let noPermission = NSError(domain: NSCocoaErrorDomain, code: 513, userInfo: nil)! as Error
check((noPermission as? CocoaError)?.code != .fileWriteFileExists, "another Cocoa code doesn't match")
check((NSError(domain: "other", code: 516, userInfo: nil)! as Error as? CocoaError) == nil, "another domain doesn't bridge")
check(CocoaError(.fileWriteFileExists)._nsError.domain() == NSCocoaErrorDomain
      && CocoaError(.fileWriteFileExists)._nsError.code() == 516, "CocoaError(code) builds an NSError")

// FileManager.enumerator(at:includingPropertiesForKeys:options:errorHandler:).
var template = Array((NSTemporaryDirectory() + "/bootcamp-enum.XXXXXX").utf8CString)
if let dirPointer = mkdtemp(&template) {
    let dir = String(cString: dirPointer)
    func touch(_ path: String) { if let f = fopen(path, "w") { fclose(f) } }
    touch(dir + "/a.txt")
    mkdir(dir + "/sub", 0o755)
    touch(dir + "/sub/b.txt")

    func names(_ enumerator: NSDirectoryEnumerator?) -> Set<String> {
        guard let enumerator = enumerator else { return ["<nil enumerator>"] }
        var result = Set<String>()
        for item in enumerator {
            if let url = item as? URL { result.insert(url.lastPathComponent) } else { result.insert("<not a URL: \(item)>") }
        }
        return result
    }
    let manager = NSFileManager.default()!
    let all = names(manager.enumerator(at: URL(fileURLWithPath: dir), includingPropertiesForKeys: nil))
    check(all == ["a.txt", "sub", "b.txt"], "enumerator(at:) visits every item (\(all))")
    let withKeys = names(manager.enumerator(at: URL(fileURLWithPath: dir),
                                            includingPropertiesForKeys: [URLResourceKey(rawValue: "NSURLIsDirectoryKey")],
                                            options: NSDirectoryEnumerationOptions(rawValue: 0),
                                            errorHandler: { _, _ in true }))
    check(withKeys == all, "enumerator(at:) with keys and an error handler (\(withKeys))")

    unlink(dir + "/sub/b.txt")
    rmdir(dir + "/sub")
    unlink(dir + "/a.txt")
    rmdir(dir)
} else {
    check(false, "mkdtemp")
}

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
