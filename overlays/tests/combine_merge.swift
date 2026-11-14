// Copyright (C) 2026 Lubos Dolezel
//
// Combine's merge(with:) and Publishers.MergeMany, from the documented behaviour: values of all upstreams arrive
// as they are sent, the merged publisher finishes after every upstream has finished, and a failure of any upstream
// fails it.
import Combine
import Darwin

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

enum TestError: Error { case boom }
var cancellables = Set<AnyCancellable>()

let first = PassthroughSubject<Int, Never>()
let second = PassthroughSubject<Int, Never>()
var values: [Int] = []
var finished = 0
first.merge(with: second)
    .sink(receiveCompletion: { _ in finished += 1 }, receiveValue: { values.append($0) })
    .store(in: &cancellables)
first.send(1)
second.send(2)
first.send(completion: .finished)
check(finished == 0, "merge waits for every upstream to finish")
second.send(3)
second.send(completion: .finished)
check(values == [1, 2, 3], "merge interleaves values in send order (\(values))")
check(finished == 1, "merge finishes once, after the last upstream")

let a = PassthroughSubject<Int, TestError>()
let b = PassthroughSubject<Int, TestError>()
var failed = false
var late: [Int] = []
a.merge(with: b)
    .sink(receiveCompletion: { if case .failure = $0 { failed = true } }, receiveValue: { late.append($0) })
    .store(in: &cancellables)
a.send(completion: .failure(.boom))
b.send(9)
check(failed && late.isEmpty, "a failure of one upstream fails the merge and stops delivery")

var many: [Int] = []
Publishers.MergeMany([Just(1).eraseToAnyPublisher(), [2, 3].publisher.eraseToAnyPublisher()])
    .sink { many.append($0) }
    .store(in: &cancellables)
check(many.sorted() == [1, 2, 3], "MergeMany delivers every upstream's values (\(many))")

var none = 0
var noneFinished = false
Publishers.MergeMany([AnyPublisher<Int, Never>]())
    .sink(receiveCompletion: { _ in noneFinished = true }, receiveValue: { _ in none += 1 })
    .store(in: &cancellables)
check(noneFinished && none == 0, "MergeMany of no publishers finishes at once")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
