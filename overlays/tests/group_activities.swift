// Copyright (C) 2026 Lubos Dolezel
//
// GroupActivities answers as a device that is not in a FaceTime call: nothing is eligible, an activity cannot
// be activated, and sessions() never delivers a session (it ends only when the task consuming it is cancelled).
// No session or messenger can be created by clients, so those members are covered by the compiler only.
import Combine
import Darwin
import Dispatch
import Foundation
import GroupActivities

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

struct WatchTogether: GroupActivity {
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = "Watch together"
        return metadata
    }
}

check(!GroupStateObserver().isEligibleForGroupSession, "a device outside a FaceTime call is not eligible")
check(GroupActivityMetadata().title == nil, "metadata starts without a title")
check(WatchTogether().metadata.title == "Watch together", "a conforming activity supplies its metadata")
check(!WatchTogether.activityIdentifier.isEmpty, "activityIdentifier has a default value")
check(WatchTogether._identifiable(by: WatchTogether.activityIdentifier), "an activity is identifiable by its identifier")
check(!WatchTogether._identifiable(by: "another.activity"), "an activity is not identifiable by another identifier")

// activate() reports that the activity was not started instead of failing.
let activated = DispatchSemaphore(value: 0)
var activationResult: Bool?
var activationError: Error?
Task {
    do { activationResult = try await WatchTogether().activate() } catch { activationError = error }
    activated.signal()
}
check(activated.wait(timeout: .now() + 5) == .success, "activate() completes")
check(activationResult == false && activationError == nil, "activate() returns false")

// sessions() delivers nothing; cancelling the consuming task ends the loop.
var sessionsDelivered = 0
let loopEnded = DispatchSemaphore(value: 0)
let consumer = Task {
    for await _ in WatchTogether.sessions() { sessionsDelivered += 1 }
    loopEnded.signal()
}
usleep(200_000)
check(sessionsDelivered == 0, "no session is delivered")
consumer.cancel()
check(loopEnded.wait(timeout: .now() + 5) == .success, "the sessions() loop ends when its task is cancelled")
check(sessionsDelivered == 0, "no session is delivered after cancellation")

// The participants type is usable.
let everyone: Participants = .all
let nobody: Participants = .only([])
switch (everyone, nobody) {
case (.all, .only(let set)): check(set.isEmpty, "Participants.only holds a set")
default: check(false, "Participants cases")
}

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
