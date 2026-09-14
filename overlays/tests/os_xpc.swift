// Exercises the clean-room os and XPC overlays under Darling.
import os
import XPC
import Dispatch

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

// os: Logger, os_log with arguments, OSLog, OSLogType, signposts, lock.
let logger = Logger(subsystem: "org.darlinghq.swift-overlay-test", category: "tests")
check(logger.logObject.isEnabled(type: .default), "Logger(subsystem:category:).logObject enabled for .default")
check(Logger().logObject === OSLog.default, "Logger() uses OSLog.default")
os_log("plain message from os_log")
"public-string".withCString { os_log("os_log with arguments: %d %{public}s %f", log: logger.logObject, type: .error, 42, $0, 2.5) }
os_log(.info, log: .default, "os_log(type:log:) %ld", 7)
check(OSLogType.error.rawValue == 0x10 && OSLogType.fault.rawValue == 0x11, "OSLogType raw values")

let signposter = OSSignposter(logger: logger)
let id = signposter.makeSignpostID()
check(id != .invalid, "makeSignpostID() != .invalid (\(id.rawValue))")
check(OSSignpostID.exclusive.rawValue == 0xEEEE_B0B5_B2B2_EEEE, "OSSignpostID.exclusive")
let state = signposter.beginInterval("interval", id: id)
check(state.signpostID == id, "OSSignpostIntervalState.signpostID")
signposter.endInterval("interval", state)
check(checkForErrorAndConsumeState(state: state) == .doubleEnd, "second end reports .doubleEnd")
os_signpost(.event, log: logger.logObject, name: "event", signpostID: id, "value %d", 1)

let counter = OSAllocatedUnfairLock(initialState: 0)
let group = DispatchGroup()
for _ in 0..<8 {
    DispatchQueue.global().async(group: group) {
        for _ in 0..<1000 { counter.withLock { $0 += 1 } }
    }
}
group.wait()
check(counter.withLock { $0 } == 8000, "OSAllocatedUnfairLock across 8 threads (\(counter.withLock { $0 }))")

// XPC: dictionaries, arrays, sessions.
var dict = XPCDictionary()
dict["flag"] = true
dict["count"] = UInt64(3)
dict["name"] = "darling"
let signed: Int? = dict["count"]
check((dict["flag"] as Bool?) == true, "XPCDictionary Bool subscript")
check(signed == 3, "XPCDictionary SignedInteger getter reads a UInt64 value")
check((dict["name"] as String?) == "darling", "XPCDictionary String subscript")
var copy = dict
copy["flag"] = false
check((dict["flag"] as Bool?) == true && (copy["flag"] as Bool?) == false, "XPCDictionary copy-on-write")
let raw: xpc_object_t? = dict["flag"]
check(raw != nil, "XPCDictionary xpc_object_t subscript")
dict["flag"] = nil as Bool?
check((dict["flag"] as Bool?) == nil, "setting nil removes the key")

let array = XPCArray()
check(array.withUnsafeUnderlyingArray { xpc_array_get_count($0) } == 0, "XPCArray.withUnsafeUnderlyingArray")

do {
    // Darling's libxpc doesn't report XPC_ERROR_CONNECTION_INVALID for a missing mach service, so only
    // check that a session can be created, used and cancelled without crashing.
    let session = try XPCSession(machService: "org.darlinghq.nonexistent-service", options: .inactive)
    var message = XPCDictionary()
    message["ping"] = true
    try session.activate()
    session.send(message: message) { _ in }
    session.cancel(reason: "test done")
    check(true, "XPCSession create/activate/send/cancel")
} catch {
    check(false, "XPCSession(machService:) threw \(error)")
}

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
