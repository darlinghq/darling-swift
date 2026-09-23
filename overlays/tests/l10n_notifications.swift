// String.LocalizationValue, LocalizedStringResource, String(localized:), NSObject's CustomStringConvertible
// conformance and NotificationCenter.notifications(named:object:) through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

// The test executable has no Localizable.strings, so localizing returns the formatted default value.
let name = "Ada"
check(String(localized: "Hello") == "Hello", "String(localized:) literal")
check(String(localized: "Hello \(name)") == "Hello Ada", "String(localized:) with a String interpolation")
check(String(localized: "\(3, specifier: "%lld") items, \(2.5, specifier: "%.1f") kg") == "3 items, 2.5 kg", "specifier interpolations")
check(String(localized: "100% of \(name)") == "100% of Ada", "a literal percent sign survives formatting")
check(String(localized: "key.greeting", defaultValue: "Hi \(name)") == "Hi Ada", "String(localized:defaultValue:)")
let placeholderKey = LocalizedStringResource("Count: \(placeholder: .int, specifier: "%lld") of 100%").key
check(placeholderKey == "Count: %lld of 100%%", "placeholder interpolation key (\(placeholderKey))")
check(String(localized: "Count: \(placeholder: .int, specifier: "%lld") of 100%") == "Count: %lld of 100%", "a placeholder key isn't formatted")

let literal: LocalizedStringResource = "Settings"
check(literal.key == "Settings" && String(localized: literal) == "Settings", "LocalizedStringResource literal")
let interpolated: LocalizedStringResource = "Welcome, \(name)"
check(interpolated.key == "Welcome, %@" && String(localized: interpolated) == "Welcome, Ada", "LocalizedStringResource interpolation")
let keyed = LocalizedStringResource("key.title", defaultValue: "Title \(7, specifier: "%lld")", table: "Missing")
check(keyed.key == "key.title" && keyed.table == "Missing" && String(localized: keyed) == "Title 7", "LocalizedStringResource(_:defaultValue:table:)")
check(literal.localizedStringResource.key == literal.key, "CustomLocalizedStringResourceConvertible")
check(String(localized: "Open \(literal)") == "Open Settings", "resource interpolation")

// A bundle with an English strings table, written at run time.
let bundleDirectory = "/tmp/darling-swift-l10n-\(getpid())"
mkdir(bundleDirectory, 0o755)
mkdir(bundleDirectory + "/en.lproj", 0o755)
try? #"<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict><key>CFBundleDevelopmentRegion</key><string>en</string><key>CFBundleIdentifier</key><string>org.darling.l10n-test</string></dict></plist>"#
    .write(to: URL(fileURLWithPath: bundleDirectory + "/Info.plist"), atomically: true, encoding: .utf8)
try? #"""
"Hello %@" = "Bonjour %@";
"order %lld %@" = "%2$@ first, then %1$lld";
"key.title" = "Translated title %lld";
"""#.write(to: URL(fileURLWithPath: bundleDirectory + "/en.lproj/Localizable.strings"), atomically: true, encoding: .utf8)
if let bundle = Bundle(url: URL(fileURLWithPath: bundleDirectory)) {
    check(String(localized: "Hello \(name)", bundle: bundle) == "Bonjour Ada", "String(localized:bundle:) uses the strings table (\(String(localized: "Hello \(name)", bundle: bundle)))")
    check(String(localized: "order \(5, specifier: "%lld") \(name)", bundle: bundle) == "Ada first, then 5", "a translation can reorder arguments")
    let fromTable = LocalizedStringResource("key.title", defaultValue: "Title \(7, specifier: "%lld")", bundle: .atURL(URL(fileURLWithPath: bundleDirectory)))
    check(String(localized: fromTable) == "Translated title 7", "LocalizedStringResource with a bundle URL")
} else {
    check(false, "test bundle at \(bundleDirectory)")
}

func describe<T : CustomStringConvertible>(_ value: T) -> String { return value.description }
check(describe(NSObject()).hasPrefix("<NSObject: "), "NSObject is CustomStringConvertible (\(describe(NSObject())))")

let center = NotificationCenter.defaultCenter() as! NotificationCenter
let notificationName = NSNotificationName(rawValue: "org.darling.async-notification")
let sender = NSObject()
let notifications = center.notifications(named: notificationName, object: sender)
var iterator = notifications.makeAsyncIterator()
center.postNotificationName("org.darling.other", object: sender)
center.postNotificationName(notificationName.rawValue, object: NSObject())
center.postNotificationName(notificationName.rawValue, object: sender)
center.postNotificationName(notificationName.rawValue, object: sender)
let first = await iterator.next()
check(first?.name == notificationName && first?.object as AnyObject? === sender, "notifications(named:object:) delivers a matching notification")
let second = await iterator.next()
check(second?.name == notificationName, "notifications are buffered in order")
DispatchQueue.global().async {
    center.postNotificationName(notificationName.rawValue, object: sender)
}
let third = await iterator.next()
check(third?.name == notificationName, "a notification posted from another thread is delivered")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
