// Foundation._FormatSpecifiable matches Apple's (no _specifier requirement, Int._arg is Int64, all integer and
// floating-point types conform), under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

// OpenSwiftUI declares its own protocol of this shape and conforms Int with `_arg: Int64`, as SwiftUI does on macOS;
// that only type-checks when Foundation's Int._arg has the same type.
protocol LocalFormatSpecifiable {
    associatedtype _Arg : CVarArg
    var _arg: _Arg { get }
}
extension Int : LocalFormatSpecifiable {
    var _arg: Int64 { return Int64(self) }
}
func argType<T : Foundation._FormatSpecifiable>(_ value: T) -> Any.Type { return type(of: value._arg) }
check(argType(5 as Int) == Int64.self && argType(Int8(1)) == Int32.self && argType(UInt(1)) == UInt64.self, "_Arg types")

check(String(localized: "\(Int8(-3), specifier: "%d") \(UInt16(65000), specifier: "%u")") == "-3 65000", "narrow integers pass as 32-bit")
check(String(localized: "\(Int.min, specifier: "%lld") \(UInt64.max, specifier: "%llu")") == "\(Int.min) \(UInt64.max)", "64-bit integers")
check(String(localized: "\(Float(0.5), specifier: "%.2f") \(CGFloat(1.25), specifier: "%.2f")") == "0.50 1.25", "Float and CGFloat")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
if failures != 0 { exit(1) }
