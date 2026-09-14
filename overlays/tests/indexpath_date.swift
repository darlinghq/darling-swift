// IndexPath and Date through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

// IndexPath
let single = IndexPath(index: 4)
let pair: IndexPath = [1, 2]
let deep = pair.appending(3)
check(single.count == 1 && single[0] == 4, "IndexPath(index:)")
check(pair.count == 2 && pair[1] == 2, "IndexPath array literal")
check(deep == [1, 2, 3], "appending and ==")
check(pair < deep && !(deep < pair) && deep > pair, "Comparable depth-first order")
check(pair.description == "[1, 2]", "description (\(pair.description))")
for path in [IndexPath(), single, pair, deep] {
    let ns = path as NSIndexPath
    check(ns.length() == path.count, "IndexPath \(path) bridges to NSIndexPath")
    check((ns as IndexPath) == path, "NSIndexPath \(path) bridges back")
}
check(Set([pair, deep, pair]).count == 2, "IndexPath is Hashable")

// Date
let start = Date()
check(abs(Date.now.timeIntervalSince(start)) < 5, "Date() and Date.now are close")
let epoch = Date(timeIntervalSince1970: 0)
check(epoch.timeIntervalSinceReferenceDate == -978307200, "timeIntervalSince1970 initializer")
check(epoch.timeIntervalSince1970 == 0, "timeIntervalSince1970")
let later = epoch.addingTimeInterval(60)
check(later > epoch && epoch < later && later - 60 == epoch, "comparison and arithmetic")
check(epoch.compare(later) == .orderedAscending, "compare returns NSComparisonResult")
check(Date.distantPast < epoch && epoch < Date.distantFuture, "distantPast/distantFuture")
let nsDate = later as NSDate
check(nsDate.timeIntervalSince1970() == 60, "Date bridges to NSDate")
check((nsDate as Date) == later, "NSDate bridges back")
check(!later.description.isEmpty, "description (\(later.description))")
check(epoch.distance(to: later) == 60 && epoch.advanced(by: 60) == later, "distance(to:) and advanced(by:)")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
