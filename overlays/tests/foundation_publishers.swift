// Copyright (C) 2026 Lubos Dolezel
//
// The Combine integration of the Foundation overlay, from the documented API: Timer.publish,
// NotificationCenter.publisher(for:), the RunLoop and OperationQueue schedulers, and
// JSONEncoder/JSONDecoder as TopLevelEncoder/TopLevelDecoder.
import Combine
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

var cancellables = Set<AnyCancellable>()

// NotificationCenter publisher: delivers posted notifications synchronously, stops after cancel().
let name = Notification.Name("FoundationPublishersTest")
var received: [Int] = []
let center = NotificationCenter()
let token = center.publisher(for: name).sink { received.append($0.userInfo?["n"] as? Int ?? -1) }
center.post(name: name, object: nil, userInfo: ["n": 1])
center.post(name: name, object: nil, userInfo: ["n": 2])
token.cancel()
center.post(name: name, object: nil, userInfo: ["n": 3])
check(received == [1, 2], "NotificationCenter publisher delivers until cancelled (\(received))")

// Timer publisher: ticks on the run loop, spaced by the interval, until cancelled.
var ticks = 0
let timerToken = Timer.publish(every: 0.05, on: .main, in: .default).autoconnect().sink { _ in ticks += 1 }
let deadline = Date().addingTimeInterval(0.6)
while ticks < 3 && Date() < deadline {
    RunLoop.main.run(mode: .default, before: Date().addingTimeInterval(0.05))
}
timerToken.cancel()
check(ticks >= 3, "Timer.publish ticks repeatedly (\(ticks))")

// RunLoop scheduler: scheduled work runs when the run loop runs, in order.
var order: [Int] = []
RunLoop.main.schedule { order.append(1) }
RunLoop.main.schedule(after: RunLoop.main.now.advanced(by: .seconds(0.05))) { order.append(2) }
let loopDeadline = Date().addingTimeInterval(0.6)
while order.count < 2 && Date() < loopDeadline {
    RunLoop.main.run(mode: .default, before: Date().addingTimeInterval(0.05))
}
check(order == [1, 2], "RunLoop scheduler runs scheduled actions in order (\(order))")

// SchedulerTimeType.Stride arithmetic.
let stride = RunLoop.SchedulerTimeType.Stride.seconds(1.5)
check(stride.timeInterval == 1.5, "RunLoop stride keeps its seconds")
check(stride + .seconds(0.5) == .seconds(2), "RunLoop strides add")
check(RunLoop.SchedulerTimeType.Stride.milliseconds(250).timeInterval == 0.25, "stride from milliseconds")

// OperationQueue scheduler: receive(on:) delivers on the queue's thread, not the caller's.
let queue = OperationQueue()
let done = DispatchSemaphore(value: 0)
var onMain: Bool?
Just(1).receive(on: queue).sink { _ in
    onMain = Thread.isMainThread
    done.signal()
}.store(in: &cancellables)
check(done.wait(timeout: .now() + 5) == .success, "OperationQueue scheduler delivers")
check(onMain == false, "OperationQueue scheduler delivers off the main thread")

// JSONEncoder and JSONDecoder as TopLevelEncoder and TopLevelDecoder.
struct Item: Codable, Equatable { var id: Int; var title: String }
var decoded: [Item] = []
var decodeFailed = false
let payload = Just(try! JSONEncoder().encode(Item(id: 7, title: "seven")))
payload.decode(type: Item.self, decoder: JSONDecoder())
    .sink(receiveCompletion: { if case .failure = $0 { decodeFailed = true } }, receiveValue: { decoded.append($0) })
    .store(in: &cancellables)
check(decoded == [Item(id: 7, title: "seven")] && !decodeFailed, "decode(type:decoder:) with JSONDecoder")

var badDecodeFailed = false
Just(Data("not json".utf8)).decode(type: Item.self, decoder: JSONDecoder())
    .sink(receiveCompletion: { if case .failure = $0 { badDecodeFailed = true } }, receiveValue: { _ in })
    .store(in: &cancellables)
check(badDecodeFailed, "decode(type:decoder:) fails on invalid JSON")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
