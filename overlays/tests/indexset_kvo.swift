// IndexSet and key-value observing through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

// IndexSet
var set = IndexSet()
check(set.isEmpty && set.count == 0 && set.first == nil, "empty IndexSet")
set.insert(5)
set.insert(integersIn: 10..<13)
set.insert(1)
check(set.count == 5, "count (\(set.count))")
check(set.first == 1 && set.last == 12, "first/last")
check(set.contains(11) && !set.contains(9), "contains")
check(Array(set) == [1, 5, 10, 11, 12], "iteration (\(Array(set)))")
check(set.rangeView.map { $0 } == [1..<2, 5..<6, 10..<13], "rangeView")
check(set.integerGreaterThan(5) == 10, "integerGreaterThan")
let other = IndexSet(integer: 5)
check(IndexSet(integer: 7).first == 7, "init(integer:)")
check(set.contains(integersIn: other), "contains(integersIn:)")
let union = other.union(IndexSet(integersIn: 0..<2))
check(Array(union) == [0, 1, 5], "union")
check(Array(set.filteredIndexSet { $0 % 2 == 0 }) == [10, 12], "filteredIndexSet")
let ns = set as NSIndexSet
check(ns.count() == 5 && ns.firstIndex() == 1, "IndexSet bridges to NSIndexSet")
check((ns as IndexSet) == set, "NSIndexSet bridges back and ==")

// Key-value observing
final class Model: NSObject {
    @objc dynamic var title: String = "start"
    @objc dynamic var count: Int = 0
    @objc dynamic var subtitle: String? = "sub"
}

let model = Model()
var titles: [String] = []
var oldValues: [String] = []
let observation = model.observe(\.title, options: NSKeyValueObservingOptions(rawValue: 0x01 | 0x02)) { object, change in
    if let new = change.newValue { titles.append(new) }
    if let old = change.oldValue { oldValues.append(old) }
}
model.title = "one"
model.title = "two"
check(titles == ["one", "two"], "observe delivers new values (\(titles))")
check(oldValues == ["start", "one"], "observe delivers old values (\(oldValues))")

var counts = 0
let countObservation = model.observe(\.count) { object, _ in
    counts += 1
    check(object === model, "change handler receives the observed object")
}
model.count = 1
observation.invalidate()
model.title = "three"
check(titles.count == 2, "invalidate() stops delivery")
check(counts == 1, "a second observation on another key path")
_ = countObservation

// An optional property set to nil is reported as .some(nil), not as a missing value.
var subtitleChanges: [String??] = []
let subtitleObservation = model.observe(\.subtitle, options: NSKeyValueObservingOptions(rawValue: 0x01)) { _, change in
    subtitleChanges.append(change.newValue)
}
model.subtitle = nil
check(subtitleChanges.count == 1 && subtitleChanges[0] != nil && subtitleChanges[0]! == nil,
      "optional property set to nil reports .some(nil) (\(subtitleChanges))")
_ = subtitleObservation

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
