import Foundation

var failures = 0
func check(_ condition: Bool, _ name: String) {
    if !condition {
        print("FAIL: \(name)")
        failures += 1
    }
}

let text = "AéB"
let middle = text.dropFirst().dropLast()
check(Array(text.data(using: .utf8) ?? Data()) == [65, 195, 169, 66], "String UTF-8")
check(Array(middle.data(using: .utf8) ?? Data()) == [195, 169], "Substring UTF-8")
check(Array(middle.data(using: .isoLatin1) ?? Data()) == [233], "Substring Latin-1")
check("☃".data(using: .ascii, allowLossyConversion: false) == nil, "ASCII rejects unrepresentable character")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
