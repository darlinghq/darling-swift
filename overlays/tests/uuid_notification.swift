// UUID and Notification through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

// UUID
let a = UUID()
let b = UUID()
check(a != b, "two random UUIDs differ")
check(a.uuidString.count == 36, "uuidString has 36 characters (\(a.uuidString))")
check(UUID(uuidString: a.uuidString) == a, "UUID(uuidString:) round-trips")
check(UUID(uuidString: "not-a-uuid") == nil, "invalid uuidString gives nil")
let fixed = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!
check(fixed.uuidString == "E621E1F8-C36C-495A-93FC-0C247A3E6E5F", "uuidString is uppercase")
let ns = fixed as NSUUID
check(ns.uuidString() == "E621E1F8-C36C-495A-93FC-0C247A3E6E5F", "UUID bridges to NSUUID")
check((ns as UUID) == fixed, "NSUUID bridges back to UUID")
check(Set([a, b, a]).count == 2, "UUID is Hashable")
check(fixed.uuid.0 == 0xE6 && fixed.uuid.15 == 0x5F, "uuid bytes")
check((a < b) != (b < a), "UUID is Comparable")

// Notification
let name = NSNotificationName(rawValue: "org.darling.probe")
// Notification's == compares objects by identity, so use a class instance (a String would be boxed anew).
let sender = NSObject()
let note = Notification(name: name, object: sender, userInfo: ["count": 3])
check(note.name == name, "Notification name")
check((note.userInfo?["count"] as? Int) == 3, "Notification userInfo")
let nsNote = note as NSNotification
check(nsNote.name() == "org.darling.probe", "Notification bridges to NSNotification")
check((nsNote.userInfo()?["count"] as? Int) == 3, "NSNotification userInfo from Swift")
let back = nsNote as Notification
check(back.name == name && (back.object as AnyObject?) === sender, "NSNotification bridges back")
check(back == note, "Notification equality after a round trip")

// Darling's +defaultCenter returns id, and NSNotification has no SwiftBridge entry, so convert explicitly.
var received: Notification?
let center = NotificationCenter.defaultCenter() as! NotificationCenter
let token = center.addObserver(forName: name.rawValue, object: nil as Any?, queue: nil as OperationQueue?) { (n: NSNotification?) in
    received = n.map { $0 as Notification }
}
center.post(Notification(name: name, userInfo: ["k": "v"]) as NSNotification)
check((received?.userInfo?["k"] as? String) == "v", "notification delivered to a Swift block observer")
center.removeObserver(token)

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
