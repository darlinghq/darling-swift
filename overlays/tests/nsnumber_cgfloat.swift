import Foundation

let value = NSNumber(value: CGFloat(1.25))
if value.doubleValue() == 1.25 {
    print("ALL PASSED")
} else {
    print("FAIL: CGFloat NSNumber value")
    exit(1)
}
