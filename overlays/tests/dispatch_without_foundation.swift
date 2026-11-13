// Copyright (C) 2026 Lubos Dolezel
// A program that imports only Dispatch (no Foundation, so CoreFoundation is not loaded) can create work items and
// submit blocks: the compiler retains the blocks it passes to dispatch with the Objective-C runtime, which needs
// the block classes to exist.
import Dispatch

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

let group = DispatchGroup()
let semaphore = DispatchSemaphore(value: 0)
var ran = 0
DispatchQueue.global().async(group: group) {
    ran += 1
    semaphore.signal()
}
semaphore.wait()
group.wait()
check(ran == 1, "DispatchQueue.global().async(group:) runs the block")

let item = DispatchWorkItem(flags: [.barrier]) { ran += 1 }
let queue = DispatchQueue(label: "dispatch_without_foundation")
queue.async(execute: item)
item.wait()
check(ran == 2, "DispatchWorkItem(flags:block:) runs on a queue")

let qosItem = DispatchWorkItem(qos: .userInitiated, flags: []) { ran += 1 }
qosItem.perform()
check(ran == 3, "DispatchWorkItem(qos:flags:block:).perform() runs the block")

DispatchQueue.global().async { semaphore.signal() }
semaphore.wait()
check(true, "DispatchQueue.global().async runs a block")

if failures == 0 {
    print("ALL PASSED")
} else {
    exit(1)
}
