// NotificationCenter's Objective-C API takes Notification.Name and delivers Notification (typed NSNotificationName
// parameters and the NSNotification SwiftBridge), under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

let ping = Notification.Name("VDTypedNotificationPing")

final class Observer : NSObject {
    var received: [Notification.Name] = []
    @objc func handle(_ note: NSNotification) { received.append(note.name()) }
}

let center = NotificationCenter.default
let observer = Observer()
let sender = NSObject()
center.addObserver(observer, selector: #selector(Observer.handle(_:)), name: ping, object: sender)
center.post(name: ping, object: sender)
check(observer.received == [ping], "addObserver(_:selector:name:object:) with a Notification.Name")

var delivered: Notification?
let token = center.addObserver(forName: ping, object: nil, queue: nil) { (note: Notification) in delivered = note }
center.post(name: ping, object: sender, userInfo: ["k": 1])
check(delivered?.name == ping && (delivered?.object as AnyObject?) === sender && delivered?.userInfo?["k"] as? Int == 1,
      "block observer receives a Notification")

center.removeObserver(observer, name: ping, object: sender)
center.removeObserver(token)
center.post(Notification(name: ping, object: sender))
check(observer.received.count == 2 && delivered?.userInfo?["k"] as? Int == 1, "removeObserver(_:name:object:) and token removal")

let made = NSNotification(name: ping, object: nil)
check(made.name() == ping && (made as Notification).name == ping, "NSNotification(name:object:) and bridging")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
if failures != 0 { exit(1) }
