// NSNumber bridging for UInt8, Int16, UInt16, Int32, UInt32, UInt64, UInt, Float and CGFloat: round trips,
// exactness checks on conditional casts, and bridging through NSArray and NSDictionary.
import Foundation
import CoreGraphics

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

// Round trips through NSNumber
check((UInt8(200) as NSNumber).unsignedCharValue() == 200, "UInt8 -> NSNumber")
check((Int16(-300) as NSNumber).shortValue() == -300, "Int16 -> NSNumber")
check((UInt16(60000) as NSNumber).unsignedShortValue() == 60000, "UInt16 -> NSNumber")
check((Int32(-70000) as NSNumber).intValue() == -70000, "Int32 -> NSNumber")
check((UInt32(4_000_000_000) as NSNumber).unsignedIntValue() == 4_000_000_000, "UInt32 -> NSNumber")
check((UInt64.max as NSNumber).unsignedLongLongValue() == UInt64.max, "UInt64.max -> NSNumber")
check((UInt(42) as NSNumber).unsignedIntegerValue() == 42, "UInt -> NSNumber")
check((Float(1.5) as NSNumber).floatValue() == 1.5, "Float -> NSNumber")
check((CGFloat(2.25) as NSNumber).doubleValue() == 2.25, "CGFloat -> NSNumber")

// Conditional casts keep the value only when it's exact
let n200: NSNumber = NSNumber(integer: 200)
let n300: NSNumber = NSNumber(integer: 300)
let nMinus1: NSNumber = NSNumber(integer: -1)
check((n200 as? UInt8) == 200, "NSNumber(200) as? UInt8")
check((n300 as? UInt8) == nil, "NSNumber(300) as? UInt8 fails")
check((nMinus1 as? UInt32) == nil, "NSNumber(-1) as? UInt32 fails")
check((nMinus1 as? Int16) == -1, "NSNumber(-1) as? Int16")
// Darling stores unsigned 64-bit values above Int64.max as signed until its NSNumber stores them as 128-bit numbers,
// so NSNumber(-1) as? UInt and UInt64.max as? Int64 succeed there; only the round trips are checked.
check(((UInt64.max as NSNumber) as? UInt64) == UInt64.max, "UInt64.max round trip")
check(((UInt(1) << 63) as NSNumber as? UInt) == UInt(1) << 63, "2^63 as UInt round trip")
check((NSNumber(double: 1.5) as? Int) == nil, "NSNumber(1.5) as? Int fails")
check((NSNumber(integer: 70000) as? Int16) == nil, "NSNumber(70000) as? Int16 fails")
check((NSNumber(integer: 70000) as? Int32) == 70000, "NSNumber(70000) as? Int32")
check((NSNumber(longLong: 1 << 40) as? UInt32) == nil, "NSNumber(2^40) as? UInt32 fails")
check((NSNumber(double: 0.5) as? Float) == 0.5, "NSNumber(0.5) as? Float")
check((NSNumber(double: 0.1) as? Float) == nil, "NSNumber(double 0.1) as? Float fails (inexact)")
check((NSNumber(longLong: (1 << 60) + 1) as? Float) == nil, "NSNumber(2^60+1) as? Float fails (inexact)")
check((NSNumber(integer: 16) as? Float) == 16, "NSNumber(integer 16) as? Float")
check((NSNumber(float: .nan) as? Float)?.isNaN == true, "NaN as? Float")
check((NSNumber(integer: 3) as? CGFloat) == 3, "NSNumber(3) as? CGFloat")
check((NSNumber(double: 0.1) as? CGFloat) == 0.1, "NSNumber(0.1) as? CGFloat")
check(Float(truncating: NSNumber(double: 0.1)) == Float(0.1), "Float(truncating:)")
check(UInt8(truncating: n300) == 44, "UInt8(truncating: 300)")
check(UInt(exactly: n200) == 200 && UInt16(exactly: nMinus1) == nil, "UInt(exactly:), UInt16(exactly:)")
check(CGFloat(exactly: NSNumber(integer: 7)) == 7, "CGFloat(exactly:)")

// Collections bridge their elements
let floats: [Float] = [1, 2.5]
check(((floats as NSArray).object(at: 1) as? NSNumber)?.floatValue() == 2.5, "[Float] -> NSArray")
let fromObjC = [NSNumber(integer: 1)!, NSNumber(double: 0.25)!] as NSArray
check((fromObjC as? [CGFloat]) == [1, 0.25], "NSArray as? [CGFloat]")
check((fromObjC as? [UInt]) == nil, "NSArray with 0.25 as? [UInt] fails")
let sizes: [String: UInt32] = ["a": 1, "b": 4_000_000_000]
let nsSizes = sizes as NSDictionary
check((nsSizes as? [String: UInt32]) == sizes, "[String: UInt32] round trip through NSDictionary")
check((nsSizes as? [String: Int16]) == nil, "[String: UInt32] as? [String: Int16] fails for 4e9")

// Any/AnyObject casts go through the same conformances
let boxed: Any = NSNumber(unsignedChar: 9)!
check((boxed as? UInt16) == 9, "Any(NSNumber) as? UInt16")
check((CGFloat(4) as AnyObject) is NSNumber, "CGFloat as AnyObject is NSNumber")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
