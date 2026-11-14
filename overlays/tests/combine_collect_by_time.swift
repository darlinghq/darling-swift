// Copyright (C) 2026 Lubos Dolezel
//
// Combine's collect(_:options:) (Publishers.CollectByTime) and the Zip Equatable conformances, from the
// documented behaviour, driven by a manual test scheduler: byTime publishes the collected array on every
// stride, byTimeOrCount also publishes when the array reaches the given size, the elements collected so far are
// published before the completion, and a failure is forwarded instead of the collected elements.
import Combine
import Darwin

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

enum TestError: Error, Equatable { case boom }

/// A scheduler whose clock only moves when the test advances it.
final class TestScheduler: Scheduler {
    struct Time: Strideable, Hashable {
        var ticks: Int
        func distance(to other: Time) -> Stride { Stride(ticks: other.ticks - ticks) }
        func advanced(by n: Stride) -> Time { Time(ticks: ticks + n.ticks) }
    }
    struct Stride: SchedulerTimeIntervalConvertible, Comparable, SignedNumeric, ExpressibleByIntegerLiteral {
        var ticks: Int
        var magnitude: Int { Swift.abs(ticks) }
        init(ticks: Int) { self.ticks = ticks }
        init(integerLiteral value: Int) { ticks = value }
        init?<T: BinaryInteger>(exactly source: T) {
            guard let v = Int(exactly: source) else { return nil }
            ticks = v
        }
        static func < (l: Stride, r: Stride) -> Bool { l.ticks < r.ticks }
        static func + (l: Stride, r: Stride) -> Stride { Stride(ticks: l.ticks + r.ticks) }
        static func - (l: Stride, r: Stride) -> Stride { Stride(ticks: l.ticks - r.ticks) }
        static func * (l: Stride, r: Stride) -> Stride { Stride(ticks: l.ticks * r.ticks) }
        static func += (l: inout Stride, r: Stride) { l.ticks += r.ticks }
        static func -= (l: inout Stride, r: Stride) { l.ticks -= r.ticks }
        static func *= (l: inout Stride, r: Stride) { l.ticks *= r.ticks }
        static func seconds(_ s: Int) -> Stride { Stride(ticks: s) }
        static func seconds(_ s: Double) -> Stride { Stride(ticks: Int(s)) }
        static func milliseconds(_ ms: Int) -> Stride { Stride(ticks: ms / 1000) }
        static func microseconds(_ us: Int) -> Stride { Stride(ticks: us / 1_000_000) }
        static func nanoseconds(_ ns: Int) -> Stride { Stride(ticks: ns / 1_000_000_000) }
    }
    typealias SchedulerTimeType = Time
    struct SchedulerOptions {}

    private final class Job { var cancelled = false; var when: Int; let interval: Int?; let action: () -> Void
        init(when: Int, interval: Int?, action: @escaping () -> Void) {
            self.when = when; self.interval = interval; self.action = action
        }
    }
    private var jobs: [Job] = []
    private var current = 0
    var now: Time { Time(ticks: current) }
    var minimumTolerance: Stride { Stride(ticks: 0) }
    var optionsSeen = 0

    var immediateCalls = 0
    var timerStarts: [(after: Int, interval: Int, now: Int)] = []
    func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
        immediateCalls += 1
        action()
    }
    func schedule(after date: Time, tolerance: Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) {
        jobs.append(Job(when: date.ticks, interval: nil, action: action))
    }
    func schedule(after date: Time, interval: Stride, tolerance: Stride, options: SchedulerOptions?,
                  _ action: @escaping () -> Void) -> Cancellable {
        if options != nil { optionsSeen += 1 }
        timerStarts.append((date.ticks, interval.ticks, current))
        let job = Job(when: date.ticks, interval: interval.ticks, action: action)
        jobs.append(job)
        return AnyCancellable { job.cancelled = true }
    }
    /// Moves the clock forward one tick at a time, running what is due.
    func advance(by ticks: Int) {
        for _ in 0..<ticks {
            current += 1
            for job in jobs where !job.cancelled && job.when == current {
                job.action()
                if let i = job.interval { job.when += i } else { job.cancelled = true }
            }
        }
    }
}

var cancellables = Set<AnyCancellable>()

// byTime: one array per stride, nothing for an empty stride.
do {
    let s = TestScheduler()
    let subject = PassthroughSubject<Int, Never>()
    var batches: [[Int]] = []
    subject.collect(.byTime(s, 5)).sink { batches.append($0) }.store(in: &cancellables)
    subject.send(1); subject.send(2)
    check(batches.isEmpty, "byTime publishes nothing before the stride")
    s.advance(by: 5)
    check(batches == [[1, 2]], "byTime publishes the array on the stride (\(batches))")
    s.advance(by: 5)
    check(batches == [[1, 2]], "byTime publishes nothing for an empty stride")
    subject.send(3)
    s.advance(by: 5)
    check(batches == [[1, 2], [3]], "byTime starts a new array after a stride (\(batches))")
}

// byTime: the elements received so far are published before the completion.
do {
    let s = TestScheduler()
    let subject = PassthroughSubject<Int, Never>()
    var events: [String] = []
    subject.collect(.byTime(s, 5))
        .sink(receiveCompletion: { _ in events.append("finished") }, receiveValue: { events.append("\($0)") })
        .store(in: &cancellables)
    subject.send(1); subject.send(2)
    subject.send(completion: .finished)
    check(events == ["[1, 2]", "finished"], "completion flushes the buffer first (\(events))")
    s.advance(by: 10)
    check(events == ["[1, 2]", "finished"], "nothing is published after the completion")
}

// byTime: finishing with nothing collected only finishes.
do {
    let s = TestScheduler()
    let subject = PassthroughSubject<Int, Never>()
    var events: [String] = []
    subject.collect(.byTime(s, 5))
        .sink(receiveCompletion: { _ in events.append("finished") }, receiveValue: { events.append("\($0)") })
        .store(in: &cancellables)
    subject.send(completion: .finished)
    check(events == ["finished"], "completion with an empty buffer publishes no array (\(events))")
}

// A failure is forwarded and the collected elements are dropped.
do {
    let s = TestScheduler()
    let subject = PassthroughSubject<Int, TestError>()
    var values: [[Int]] = []
    var failure: TestError?
    subject.collect(.byTime(s, 5))
        .sink(receiveCompletion: { if case let .failure(e) = $0 { failure = e } },
              receiveValue: { values.append($0) })
        .store(in: &cancellables)
    subject.send(1)
    subject.send(completion: .failure(.boom))
    check(failure == .boom, "the failure is forwarded")
    check(values.isEmpty, "the collected elements are dropped on failure (\(values))")
}

// byTimeOrCount: publishes when the array is full, and on the stride.
do {
    let s = TestScheduler()
    let subject = PassthroughSubject<Int, Never>()
    var batches: [[Int]] = []
    subject.collect(.byTimeOrCount(s, 5, 3)).sink { batches.append($0) }.store(in: &cancellables)
    subject.send(1); subject.send(2)
    check(batches.isEmpty, "byTimeOrCount waits while neither the size nor the stride is reached")
    subject.send(3)
    check(batches == [[1, 2, 3]], "byTimeOrCount publishes when the array reaches the size (\(batches))")
    subject.send(4)
    s.advance(by: 5)
    check(batches == [[1, 2, 3], [4]], "byTimeOrCount publishes a partial array on the stride (\(batches))")
    subject.send(5); subject.send(6); subject.send(7); subject.send(8)
    check(batches == [[1, 2, 3], [4], [5, 6, 7]], "it keeps the extra element (\(batches))")
    subject.send(completion: .finished)
    check(batches == [[1, 2, 3], [4], [5, 6, 7], [8]], "completion flushes a partial array (\(batches))")
}

/// A downstream with fixed demand that logs the arrays it receives and the order of events.
final class Sink: Subscriber {
    typealias Input = [Int]
    typealias Failure = TestError
    var subscription: Subscription?
    var log: [String] = []
    let initial: Subscribers.Demand
    init(_ initial: Subscribers.Demand) { self.initial = initial }
    func receive(subscription: Subscription) {
        log.append("subscription")
        self.subscription = subscription
        if initial != .none { subscription.request(initial) }
    }
    func receive(_ input: [Int]) -> Subscribers.Demand { log.append("\(input)"); return .none }
    func receive(completion: Subscribers.Completion<TestError>) {
        log.append(completion == .finished ? "finished" : "failed")
    }
}
extension Subscribers.Completion where Failure: Equatable {
    static func == (l: Self, r: Self) -> Bool {
        switch (l, r) {
        case (.finished, .finished): return true
        case let (.failure(a), .failure(b)): return a == b
        default: return false
        }
    }
}

func upstream(_ s: PassthroughSubject<Int, TestError>, _ requests: Box) -> AnyPublisher<Int, TestError> {
    s.handleEvents(receiveRequest: { requests.values.append("\($0)") }).eraseToAnyPublisher()
}
final class Box { var values: [String] = [] }

// QUIRK (macOS behaviour, observed black-box on macOS 26.7.3): the timer is created when the upstream subscription arrives, one stride
// after the current time, before the downstream receives its subscription.
do {
    let s = TestScheduler()
    s.advance(by: 3)
    let subject = PassthroughSubject<Int, TestError>()
    let sink = Sink(.unlimited)
    subject.collect(.byTime(s, 5)).subscribe(sink)
    check(s.timerStarts.count == 1 && s.timerStarts[0].after == 8 && s.timerStarts[0].interval == 5,
          "QUIRK timer starts one stride after the subscription")
    subject.send(1)
    s.advance(by: 4)
    check(sink.log == ["subscription"], "QUIRK nothing before the first stride")
    s.advance(by: 1)
    check(sink.log == ["subscription", "[1]"], "QUIRK first stride is relative to the subscription (\(sink.log))")
}

// QUIRK (macOS behaviour, observed black-box on macOS 26.7.3): upstream demand. byTime forwards the downstream demand and requests one
// more element per received element; byTimeOrCount requests demand * count; no downstream demand, no request.
do {
    let s = TestScheduler()
    let subject = PassthroughSubject<Int, TestError>()
    let requests = Box()
    let sink = Sink(.unlimited)
    upstream(subject, requests).collect(.byTime(s, 5)).subscribe(sink)
    check(requests.values == ["unlimited"], "QUIRK byTime unlimited demand is forwarded (\(requests.values))")
    subject.send(1)
    check(requests.values == ["unlimited", "max(1)"], "QUIRK byTime requests one more per element (\(requests.values))")

    let s2 = TestScheduler()
    let subject2 = PassthroughSubject<Int, TestError>()
    let requests2 = Box()
    let sink2 = Sink(.none)
    upstream(subject2, requests2).collect(.byTimeOrCount(s2, 5, 3)).subscribe(sink2)
    check(requests2.values.isEmpty, "QUIRK no downstream demand requests nothing upstream")
    subject2.send(1)
    sink2.subscription?.request(.max(2))
    check(requests2.values == ["max(6)"], "QUIRK byTimeOrCount requests demand * count (\(requests2.values))")
    subject2.send(2); subject2.send(3)
    s2.advance(by: 5)
    check(sink2.log == ["subscription", "[2, 3]"], "elements sent without upstream demand are dropped upstream (\(sink2.log))")
}

// QUIRK (macOS behaviour, observed black-box on macOS 26.7.3): a stride publishes only while the downstream has demand; the elements wait
// for a later stride, and a request does not publish by itself.
do {
    let s = TestScheduler()
    let subject = PassthroughSubject<Int, TestError>()
    let sink = Sink(.max(1))
    subject.collect(.byTime(s, 5)).subscribe(sink)
    subject.send(1); subject.send(2)
    s.advance(by: 5)
    subject.send(3)
    s.advance(by: 5)
    check(sink.log == ["subscription", "[1, 2]"], "no array without demand (\(sink.log))")
    sink.subscription?.request(.max(1))
    check(sink.log == ["subscription", "[1, 2]"], "a request does not publish by itself")
    subject.send(4)
    s.advance(by: 5)
    check(sink.log == ["subscription", "[1, 2]", "[3, 4]"], "held elements are published on the next stride (\(sink.log))")
}

// QUIRK (macOS behaviour, observed black-box on macOS 26.7.3): the count-triggered array and the completion are delivered through
// scheduler.schedule(options:); the pending elements of a normal completion are published even without demand,
// then the completion in a separate scheduled call.
do {
    let s = TestScheduler()
    let subject = PassthroughSubject<Int, TestError>()
    let sink = Sink(.max(1))
    subject.collect(.byTime(s, 5)).subscribe(sink)
    subject.send(1)
    s.advance(by: 5)
    let before = s.immediateCalls
    subject.send(5)
    subject.send(completion: .finished)
    check(sink.log == ["subscription", "[1]", "[5]", "finished"], "QUIRK completion flushes regardless of demand (\(sink.log))")
    check(s.immediateCalls - before == 2, "QUIRK flush and completion are separate scheduled calls")

    let s2 = TestScheduler()
    let subject2 = PassthroughSubject<Int, TestError>()
    let sink2 = Sink(.unlimited)
    subject2.collect(.byTimeOrCount(s2, 5, 2)).subscribe(sink2)
    subject2.send(1); subject2.send(2)
    check(s2.immediateCalls == 1 && sink2.log.last == "[1, 2]", "QUIRK a full array goes through schedule(options:)")

    let s3 = TestScheduler()
    let subject3 = PassthroughSubject<Int, TestError>()
    let sink3 = Sink(.unlimited)
    subject3.collect(.byTime(s3, 5)).subscribe(sink3)
    subject3.send(1)
    subject3.send(completion: .failure(.boom))
    check(sink3.log == ["subscription", "failed"] && s3.immediateCalls == 1,
          "QUIRK failure is delivered through schedule(options:) and drops the pending elements (\(sink3.log))")
}

// QUIRK (macOS behaviour, observed black-box on macOS 26.7.3): a count below 1 behaves like a count of 1; a count-triggered array does not
// restart the timer.
do {
    let s = TestScheduler()
    let subject = PassthroughSubject<Int, TestError>()
    let sink = Sink(.unlimited)
    subject.collect(.byTimeOrCount(s, 5, 0)).subscribe(sink)
    subject.send(1); subject.send(2)
    check(sink.log == ["subscription", "[1]", "[2]"], "QUIRK count 0 publishes every element alone (\(sink.log))")

    let s2 = TestScheduler()
    let subject2 = PassthroughSubject<Int, TestError>()
    let sink2 = Sink(.unlimited)
    subject2.collect(.byTimeOrCount(s2, 5, 2)).subscribe(sink2)
    s2.advance(by: 3)
    subject2.send(1); subject2.send(2); subject2.send(3)
    s2.advance(by: 1)
    check(sink2.log == ["subscription", "[1, 2]"], "the remaining element waits (\(sink2.log))")
    s2.advance(by: 1)
    check(sink2.log == ["subscription", "[1, 2]", "[3]"], "QUIRK the timer is not restarted by a full array (\(sink2.log))")
}

// Cancelling stops the timer and the subscription.
do {
    let s = TestScheduler()
    let subject = PassthroughSubject<Int, Never>()
    var batches: [[Int]] = []
    let c = subject.collect(.byTime(s, 5)).sink { batches.append($0) }
    subject.send(1)
    c.cancel()
    s.advance(by: 10)
    check(batches.isEmpty, "a cancelled subscription publishes nothing")
}

// The options reach the scheduler.
do {
    let s = TestScheduler()
    let subject = PassthroughSubject<Int, Never>()
    subject.collect(.byTime(s, 5), options: TestScheduler.SchedulerOptions()).sink { _ in }.store(in: &cancellables)
    check(s.optionsSeen == 1, "the scheduler options are passed on")
}

// The publisher exposes what it was built from.
do {
    let s = TestScheduler()
    let p = PassthroughSubject<Int, Never>().collect(.byTimeOrCount(s, 5, 3))
    if case let .byTimeOrCount(_, stride, count) = p.strategy {
        check(stride.ticks == 5 && count == 3, "strategy is kept")
    } else {
        check(false, "strategy is kept")
    }
    check(p.options == nil, "options default to nil")
}

// Zip Equatable: equal when the upstream publishers are equal, position by position.
check(Publishers.Zip(Just(1), Just("a")) == Publishers.Zip(Just(1), Just("a")), "Zip == equal")
check(Publishers.Zip(Just(1), Just("a")) != Publishers.Zip(Just(1), Just("b")), "Zip != second differs")
check(Publishers.Zip(Just(1), Just("a")) != Publishers.Zip(Just(2), Just("a")), "Zip != first differs")
check(Publishers.Zip3(Just(1), Just(2), Just(3)) == Publishers.Zip3(Just(1), Just(2), Just(3)), "Zip3 == equal")
check(Publishers.Zip3(Just(1), Just(2), Just(3)) != Publishers.Zip3(Just(1), Just(2), Just(4)), "Zip3 != third differs")
check(Publishers.Zip4(Just(1), Just(2), Just(3), Just(4)) == Publishers.Zip4(Just(1), Just(2), Just(3), Just(4)),
      "Zip4 == equal")
check(Publishers.Zip4(Just(1), Just(2), Just(3), Just(4)) != Publishers.Zip4(Just(0), Just(2), Just(3), Just(4)),
      "Zip4 != first differs")

print(failures == 0 ? "PASS" : "FAIL (\(failures))")
exit(failures == 0 ? 0 : 1)
