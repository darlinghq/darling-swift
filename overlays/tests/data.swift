// Data through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

// Construction and inline/large representations
let small = Data([1, 2, 3])
check(small.count == 3 && small[1] == 2, "small inline Data")
var large = Data(count: 100_000)
large[99_999] = 7
check(large.count == 100_000 && large[99_999] == 7, "large Data subscripting")
large.append(contentsOf: [8, 9])
check(large.count == 100_002 && large.last == 9, "append to large Data")
let slice = large[99_999..<100_002]
check(Array(slice) == [7, 8, 9], "slices")
check(Data("héllo".utf8).count == 6, "Data from a UTF-8 view")

// Mutation and equality
var d = Data([0, 1, 2, 3, 4, 5])
d.replaceSubrange(1..<3, with: [9, 9, 9])
check(Array(d) == [0, 9, 9, 9, 3, 4, 5], "replaceSubrange")
check(d.subdata(in: 1..<4) == Data([9, 9, 9]), "subdata and equality")
check(Set([small, Data([1, 2, 3]), d]).count == 2, "Data is Hashable")

// Bridging
let ns = small as NSData
check(ns.length() == 3, "Data bridges to NSData")
check((ns as Data) == small, "NSData bridges back")
let objc = NSData(bytes: [5, 6, 7] as [UInt8], length: 3)!
let fromObjC = objc as Data
check(Array(fromObjC) == [5, 6, 7], "NSData created in ObjC bridges to Data")
let mutable = NSMutableData(bytes: [1, 2] as [UInt8], length: 2)!
var copied = mutable as Data
copied.append(3)
check(mutable.length() == 2 && copied.count == 3, "mutating a bridged copy doesn't change the NSMutableData")

// Base64 and files
check(small.base64EncodedString() == "AQID", "base64EncodedString (\(small.base64EncodedString()))")
check(Data(base64Encoded: "AQID") == small, "init(base64Encoded:)")
let url = URL(fileURLWithPath: "/tmp/darling-swift-data-test.bin")
do {
    try large.write(to: url)
    let read = try Data(contentsOf: url)
    check(read == large, "write(to:) and init(contentsOf:) round-trip")
} catch {
    check(false, "file round-trip threw \(error)")
}
check(d.range(of: Data([9, 9])) == 1..<3, "range(of:)")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
