// Copyright (C) 2026 Lubos Dolezel
//
// DispatchQueue as a Combine Scheduler, from the documented API: scheduled actions run on the queue, in order,
// receive(on:) delivers on the queue, and the scheduler time type and stride do arithmetic.
import Combine
import Darwin
import Dispatch

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

var cancellables = Set<AnyCancellable>()
let queue = DispatchQueue(label: "dispatch-scheduler-test")
let queueKey = DispatchSpecificKey<Bool>()
queue.setSpecific(key: queueKey, value: true)

// schedule(options:_:) runs the action on the queue, in submission order.
let done = DispatchSemaphore(value: 0)
var order: [Int] = []
var onQueue = true
queue.schedule { order.append(1); onQueue = onQueue && DispatchQueue.getSpecific(key: queueKey) == true }
queue.schedule { order.append(2); done.signal() }
check(done.wait(timeout: .now() + 5) == .success, "scheduled actions run")
check(order == [1, 2], "scheduled actions keep their order (\(order))")
check(onQueue, "scheduled actions run on the queue")

// schedule(after:) runs later than now.
let delayed = DispatchSemaphore(value: 0)
let start = queue.now
var elapsedNanoseconds: Int = 0
queue.schedule(after: start.advanced(by: .milliseconds(100))) {
    elapsedNanoseconds = Int(DispatchTime.now().uptimeNanoseconds &- start.dispatchTime.uptimeNanoseconds)
    delayed.signal()
}
check(delayed.wait(timeout: .now() + 5) == .success, "a delayed action runs")
check(elapsedNanoseconds >= 90_000_000, "schedule(after:) waits for the requested time (\(elapsedNanoseconds) ns)")

// receive(on:) delivers on the queue, not on the caller's thread.
let received = DispatchSemaphore(value: 0)
var deliveredOnQueue: Bool?
Just(1).receive(on: queue).sink { _ in
    deliveredOnQueue = DispatchQueue.getSpecific(key: queueKey)
    received.signal()
}.store(in: &cancellables)
check(received.wait(timeout: .now() + 5) == .success, "receive(on:) delivers")
check(deliveredOnQueue == true, "receive(on:) delivers on the queue")

// Stride arithmetic and ordering.
typealias Stride = DispatchQueue.SchedulerTimeType.Stride
check(Stride.seconds(1.5) + Stride.seconds(0.5) == Stride.seconds(2), "strides add")
check(Stride.milliseconds(250).timeInterval == .nanoseconds(250_000_000), "stride from milliseconds")
check(Stride.seconds(1) < Stride.seconds(2), "strides compare")
let t0 = queue.now
let t1 = t0.advanced(by: .seconds(1))
check(t0 < t1 && t0.distance(to: t1) == Stride.seconds(1), "scheduler times advance and measure distance")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
