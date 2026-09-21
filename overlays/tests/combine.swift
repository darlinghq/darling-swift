// Exercises the Combine framework under Darling: that publishers actually publish, not just that
// the framework loads. The @Published/objectWillChange cases are the surface apps bind most.
import Combine

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

var cancellables = Set<AnyCancellable>()

// Just: one value, then a finished completion.
var justValue: Int?
var justFinished = false
Just(42).sink(receiveCompletion: { if case .finished = $0 { justFinished = true } },
              receiveValue: { justValue = $0 })
    .store(in: &cancellables)
check(justValue == 42, "Just delivers its value to a sink")
check(justFinished, "Just finishes")

// PassthroughSubject forwards what is sent after subscription.
let subject = PassthroughSubject<Int, Never>()
var forwarded: [Int] = []
subject.sink { forwarded.append($0) }.store(in: &cancellables)
subject.send(1)
subject.send(2)
subject.send(3)
check(forwarded == [1, 2, 3], "PassthroughSubject forwards sent values")

// CurrentValueSubject replays its current value on subscription and tracks writes.
let current = CurrentValueSubject<String, Never>("initial")
var seen: [String] = []
current.sink { seen.append($0) }.store(in: &cancellables)
current.send("updated")
check(seen.first == "initial", "CurrentValueSubject replays its current value")
check(seen.last == "updated", "CurrentValueSubject forwards later values")
check(current.value == "updated", "CurrentValueSubject.value tracks sends")

// An operator chain transforms values in order.
var mapped: [Int] = []
[1, 2, 3, 4, 5].publisher
    .filter { $0 % 2 == 1 }
    .map { $0 * 10 }
    .sink { mapped.append($0) }
    .store(in: &cancellables)
check(mapped == [10, 30, 50], "filter and map compose")

// ObservableObject and @Published. objectWillChange fires through the _enclosingInstance
// subscript, which is the mechanism behind the symbols SwiftUI-era apps bind.
final class Model: ObservableObject {
    @Published var count: Int = 0
    @Published var name: String = "start"
}

let model = Model()
var willChangeCount = 0
model.objectWillChange.sink { _ in willChangeCount += 1 }.store(in: &cancellables)

var publishedValues: [Int] = []
model.$count.sink { publishedValues.append($0) }.store(in: &cancellables)

model.count = 1
model.count = 2
model.name = "changed"

check(publishedValues == [0, 1, 2], "@Published projected value replays and forwards")
check(willChangeCount == 3, "objectWillChange fires once per @Published mutation")
check(model.count == 2 && model.name == "changed", "@Published stores the written value")

// Cancelling stops delivery.
let cancelSubject = PassthroughSubject<Int, Never>()
var afterCancel: [Int] = []
let token = cancelSubject.sink { afterCancel.append($0) }
cancelSubject.send(1)
token.cancel()
cancelSubject.send(2)
check(afterCancel == [1], "AnyCancellable.cancel stops delivery")

// A failure arrives as a failure completion, not as a value.
enum TestError: Error { case boom }
var failureSeen = false
var valueAfterFailure = false
Fail<Int, TestError>(error: .boom)
    .sink(receiveCompletion: { if case .failure = $0 { failureSeen = true } },
          receiveValue: { _ in valueAfterFailure = true })
    .store(in: &cancellables)
check(failureSeen && !valueAfterFailure, "Fail delivers a failure completion")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
