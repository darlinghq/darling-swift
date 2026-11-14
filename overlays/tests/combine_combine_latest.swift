// Copyright (C) 2026 Lubos Dolezel
//
// Combine's combineLatest, from the documented behaviour: nothing is published until every upstream has produced
// a value, then each new value publishes the tuple of the latest values; it finishes after all upstreams have
// finished, and fails when any upstream fails.
import Combine
import Darwin

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

enum TestError: Error { case boom }
var cancellables = Set<AnyCancellable>()

let a = PassthroughSubject<Int, Never>()
let b = PassthroughSubject<String, Never>()
var pairs: [String] = []
var finished = 0
a.combineLatest(b)
    .sink(receiveCompletion: { _ in finished += 1 }, receiveValue: { pairs.append("\($0.0)\($0.1)") })
    .store(in: &cancellables)
a.send(1)
a.send(2)
check(pairs.isEmpty, "nothing is published before every upstream has a value")
b.send("x")
check(pairs == ["2x"], "the first tuple holds the latest values (\(pairs))")
a.send(3)
b.send("y")
check(pairs == ["2x", "3x", "3y"], "each new value publishes a tuple (\(pairs))")
a.send(completion: .finished)
check(finished == 0, "it keeps running while an upstream is live")
b.send("z")
check(pairs.last == "3z", "a finished upstream keeps its last value")
b.send(completion: .finished)
check(finished == 1, "it finishes after every upstream has finished")

let c = PassthroughSubject<Int, Never>()
var triples: [[Int]] = []
Publishers.CombineLatest3(c, Just(10), Just(100))
    .sink { triples.append([$0, $1, $2]) }
    .store(in: &cancellables)
c.send(1)
check(triples == [[1, 10, 100]], "CombineLatest3 (\(triples))")

let d = PassthroughSubject<Int, Never>()
var quads: [Int] = []
d.combineLatest(Just(1), Just(2), Just(3)) { $0 + $1 + $2 + $3 }
    .sink { quads.append($0) }
    .store(in: &cancellables)
d.send(10)
check(quads == [16], "combineLatest of four with a transform (\(quads))")

let e = PassthroughSubject<Int, TestError>()
let f = PassthroughSubject<Int, TestError>()
var failed = false
e.combineLatest(f)
    .sink(receiveCompletion: { if case .failure = $0 { failed = true } }, receiveValue: { _ in })
    .store(in: &cancellables)
e.send(completion: .failure(.boom))
check(failed, "a failure of one upstream fails the result")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
