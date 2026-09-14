// Array/Dictionary/Set <-> NSArray/NSDictionary/NSSet bridging through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

final class Item: NSObject {}

// Array
let strings = ["a", "béta", "🦀"]
let nsStrings = strings as NSArray
check(nsStrings.count() == 3, "[String] as NSArray keeps count")
check((nsStrings as! [String]) == strings, "NSArray as! [String] round-trips")
check((nsStrings as? [Int]) == nil, "NSArray of strings as? [Int] fails")
let ints = [1, 2, 3] as NSArray
check((ints as! [Int]) == [1, 2, 3], "[Int] bridged through NSArray")
let items = [Item(), Item()]
let nsItems = items as NSArray
check((nsItems as! [Item])[1] === items[1], "[NSObject subclass] bridged verbatim keeps identity")
// Darling's headers have no nullability, so initializers import as returning optionals.
let mutable = NSMutableArray()!
mutable.add("from ObjC")
mutable.add("array")
check((mutable as! [String]) == ["from ObjC", "array"], "NSMutableArray built in ObjC bridges to [String]")
let emptyFromNil = Array<String>._unconditionallyBridgeFromObjectiveC(nil)
check(emptyFromNil.isEmpty, "nil NSArray bridges to an empty array")

// Dictionary
let dict: [String: Int] = ["one": 1, "two": 2]
let nsDict = dict as NSDictionary
check(nsDict.count() == 2, "[String: Int] as NSDictionary keeps count")
check((nsDict as! [String: Int]) == dict, "NSDictionary as! [String: Int] round-trips")
check((nsDict as? [String: String]) == nil, "NSDictionary as? wrong value type fails")
let mutableDict = NSMutableDictionary()
mutableDict.setObject(42, forKey: "answer" as NSString)
let fromObjC = mutableDict as! [String: Any]
check((fromObjC["answer"] as? Int) == 42, "NSMutableDictionary built in ObjC bridges to [String: Any]")

// Set
let set: Set<String> = ["x", "y", "z"]
let nsSet = set as NSSet
check(nsSet.count() == 3, "Set<String> as NSSet keeps count")
check((nsSet as! Set<String>) == set, "NSSet as! Set<String> round-trips")
check((nsSet as? Set<Int>) == nil, "NSSet as? wrong element type fails")
let intSet = Set([4, 5]) as NSSet
check((intSet as! Set<Int>) == [4, 5], "Set<Int> bridged through NSSet")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
