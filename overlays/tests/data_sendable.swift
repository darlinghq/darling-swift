// Data is Sendable through the Foundation overlay, under Darling.
// Build with -swift-version 6: the conformance is checked by the compiler, and language mode 5 only warns about it.
import Foundation

var failures = 0
@MainActor func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

// Compile-time: each of these is an error in language mode 6 while Data is not Sendable.
func requireSendable<T: Sendable>(_: T.Type) {}
requireSendable(Data.self)

struct Payload: Sendable {
    static let magic = Data([0xCA, 0xFE])
    let body: Data
}
let sharedBytes = Data([1, 2, 3])

// Run time: values survive the hop between tasks, and a mutated copy does not write through to the original.
let payload = Payload(body: Data(repeating: 7, count: 100_000))
let sendableCount: @Sendable () -> Int = { payload.body.count + sharedBytes.count }
check(sendableCount() == 100_003, "a @Sendable closure captures Data")

let produced = await Task.detached { Payload(body: Data([4, 5, 6])) }.value
check(Array(produced.body) == [4, 5, 6] && Payload.magic == Data([0xCA, 0xFE]), "a Task returns a Sendable struct holding Data")

let echoed = await Task.detached { [body = payload.body] in body }.value
var changed = echoed
changed[0] = 1
check(echoed == payload.body && echoed[0] == 7 && changed[0] == 1, "large Data sent through a Task keeps value semantics")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
