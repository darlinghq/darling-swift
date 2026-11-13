// NSNumber(value:) for every numeric type (the -initWith<Type>: initializers Swift-named init(value:)), under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

check(NSNumber(value: Int8(-5)).longLongValue() == -5, "Int8")
check(NSNumber(value: UInt8(250)).longLongValue() == 250, "UInt8")
check(NSNumber(value: Int16(-30000)).longLongValue() == -30000, "Int16")
check(NSNumber(value: UInt16(65000)).longLongValue() == 65000, "UInt16")
check(NSNumber(value: Int32(-2_000_000_000)).longLongValue() == -2_000_000_000, "Int32")
check(NSNumber(value: UInt32(4_000_000_000)).longLongValue() == 4_000_000_000, "UInt32")
check(NSNumber(value: Int64(-1) << 40).longLongValue() == -(1 << 40), "Int64")
check(NSNumber(value: UInt64.max).unsignedLongLongValue() == UInt64.max, "UInt64")
check(NSNumber(value: -7).longLongValue() == -7, "Int")
check(NSNumber(value: UInt(1) << 63).unsignedLongLongValue() == UInt64(1) << 63, "UInt")
check(NSNumber(value: Float(0.5)).doubleValue() == 0.5, "Float")
check(NSNumber(value: 0.1).doubleValue() == 0.1, "Double")
check(NSNumber(value: true).boolValue() && !NSNumber(value: false).boolValue(), "Bool")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
if failures != 0 { exit(1) }
