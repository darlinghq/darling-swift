// NSObject.KeyValueObservingPublisher and publisher(for:options:) under Darling: KVO changes
// arriving through Combine, including the .initial value, didChange(), cancellation and demand.
import Combine
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

class Model: NSObject {
    @objc dynamic var title: String = "start"
    @objc dynamic var count: Int = 0
}

let model = Model()

// The default options are [.initial, .new]: the current value first, then each change.
var titles: [String] = []
let titleSink = model.publisher(for: \.title).sink { titles.append($0) }
model.title = "one"
model.title = "two"
check(titles == ["start", "one", "two"], "default options deliver the initial value and changes (\(titles))")

// Cancelling stops delivery.
titleSink.cancel()
model.title = "three"
check(titles.count == 3, "cancel() stops delivery (\(titles))")

// Without .initial only changes arrive.
var counts: [Int] = []
let countSink = model.publisher(for: \.count, options: [.new]).sink { counts.append($0) }
model.count = 1
model.count = 2
check(counts == [1, 2], "options [.new] delivers only changes (\(counts))")
countSink.cancel()

// didChange() maps every change to Void.
var changes = 0
let didChangeSink = model.publisher(for: \.count, options: [.new]).didChange().sink { changes += 1 }
model.count = 3
model.count = 4
check(changes == 2, "didChange() fires once per change (\(changes))")
didChangeSink.cancel()

// A subscriber asking for one value gets the cached initial value and nothing past its demand.
final class OneShot: Subscriber {
    typealias Input = String
    typealias Failure = Never
    var received: [String] = []
    var subscription: Subscription?
    func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.max(1))
    }
    func receive(_ input: String) -> Subscribers.Demand {
        received.append(input)
        return .none
    }
    func receive(completion: Subscribers.Completion<Never>) {}
}
model.title = "four"
let oneShot = OneShot()
model.publisher(for: \.title).subscribe(oneShot)
model.title = "five"
check(oneShot.received == ["four"], "demand of one delivers only the initial value (\(oneShot.received))")
oneShot.subscription?.cancel()

// Publishers with the same object, key path and options are equal.
let publisherType: NSObject.KeyValueObservingPublisher<Model, Int>.Type = type(of: model.publisher(for: \.count))
check(publisherType == NSObject.KeyValueObservingPublisher<Model, Int>.self, "publisher(for:) returns NSObject.KeyValueObservingPublisher")
check(model.publisher(for: \.count) == model.publisher(for: \.count), "equal publishers compare equal")
check(model.publisher(for: \.count) != model.publisher(for: \.count, options: [.new]), "different options compare unequal")
check(model.publisher(for: \.count) != Model().publisher(for: \.count), "different objects compare unequal")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
