// String(cString:encoding:), String(format:locale:) and StringProtocol.lowercased(with:)/capitalized(with:)
// through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

let utf8: [CChar] = [0x68, -0x3d, -0x57, 0x00] // "hé" in UTF-8
check(utf8.withUnsafeBufferPointer { String(cString: $0.baseAddress!, encoding: .utf8) } == "h\u{e9}", "cString UTF-8")
let latin1: [CChar] = [0x68, -0x17, 0x00] // "hé" in ISO Latin 1
check(latin1.withUnsafeBufferPointer { String(cString: $0.baseAddress!, encoding: .isoLatin1) } == "h\u{e9}", "cString ISO Latin 1")
check(latin1.withUnsafeBufferPointer { String(cString: $0.baseAddress!, encoding: .utf8) } == nil, "invalid UTF-8 is nil")

let french = Locale(identifier: "fr_FR")
// Darling's -initWithFormat:locale:arguments: does not yet apply the locale's decimal separator, so compare with it.
let formatted = String(format: "%.1f", locale: french, 1.5)
let objcFormatted = withVaList([1.5]) { NSString(format: "%.1f", locale: french, arguments: $0)! as String }
check(formatted == objcFormatted, "format:locale: forwards to -initWithFormat:locale:arguments: (\(formatted))")
check(String(format: "%d-%@", locale: nil, arguments: [7, "x"]) == "7-x", "format:locale:arguments: with nil locale")

let turkish = Locale(identifier: "tr_TR")
check("TITLE".lowercased(with: nil) == "title", "lowercased(with: nil)")
check("hello world"[...].capitalized(with: nil) == "Hello World", "capitalized(with:) on a Substring")
check("I".lowercased(with: turkish) == "\u{131}", "lowercased(with: tr_TR) gives dotless i")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
if failures != 0 { exit(1) }
