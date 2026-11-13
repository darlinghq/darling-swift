// Objective-C Foundation APIs taking or returning NSDate, NSLocale, NSTimeZone, NSCalendar, NSURL, NSCharacterSet
// and NSDateInterval import with the Swift value types (Foundation.apinotes SwiftBridge), under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

let date = Date(timeIntervalSince1970: 1610712000) // 2021-01-15 12:00:00 UTC
let utc = TimeZone(identifier: "UTC")!
var gregorian = Calendar(identifier: .gregorian)
gregorian.timeZone = utc

let formatter = DateFormatter()
formatter.locale = Locale(identifier: "en_US_POSIX")
formatter.timeZone = utc
formatter.calendar = gregorian
formatter.dateFormat = "yyyy-MM-dd HH:mm"
let formatted: String? = formatter.string(from: date)
check(formatted == "2021-01-15 12:00", "string(from: Date) (\(String(describing: formatted)))")
let parsed: Date? = formatter.date(from: "2021-01-15 12:00")
check(parsed == date, "date(from:) returns Date (\(String(describing: parsed)))")
let locale: Locale? = formatter.locale
check(locale?.identifier.hasPrefix("en_US_POSIX") == true, "locale returns Locale (\(String(describing: locale?.identifier)))")
let timeZone: TimeZone? = formatter.timeZone
check(timeZone?.identifier == "UTC", "timeZone returns TimeZone (\(String(describing: timeZone?.identifier)))")
let calendar: Calendar? = formatter.calendar
check(calendar?.identifier == .gregorian, "calendar returns Calendar")

let base = URL(fileURLWithPath: "/tmp/dir", isDirectory: true)
let appended: URL? = (base as NSURL).appendingPathComponent("file.txt")
check(appended?.path == "/tmp/dir/file.txt", "NSURL method returns URL (\(String(describing: appended?.path)))")

let trimmed = NSString(string: "  padded  ").trimmingCharacters(in: CharacterSet.whitespaces)
check(trimmed == "padded", "trimmingCharacters(in: CharacterSet) (\(String(describing: trimmed)))")

let interval = DateInterval(start: date, duration: 3600)
let nsInterval = interval as NSDateInterval
check(nsInterval.duration == 3600 && (nsInterval.startDate as Date?) == date, "DateInterval bridges to NSDateInterval")
let overlap: DateInterval? = nsInterval.intersection(with: DateInterval(start: date.addingTimeInterval(1800), duration: 3600))
check(overlap == DateInterval(start: date.addingTimeInterval(1800), duration: 1800), "intersection(with:) returns DateInterval (\(String(describing: overlap)))")
check(nsInterval.contains(date.addingTimeInterval(60)), "contains(Date)")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
if failures != 0 { exit(1) }
