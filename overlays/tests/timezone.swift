// TimeZone through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

// 2021-01-15 12:00:00 UTC and 2021-07-15 12:00:00 UTC
let winter = Date(timeIntervalSince1970: 1610712000)
let summer = Date(timeIntervalSince1970: 1626350400)

if let newYork = TimeZone(identifier: "America/New_York") {
    check(newYork.identifier == "America/New_York", "init(identifier:)")
    check(newYork.secondsFromGMT(for: winter) == -5 * 3600, "secondsFromGMT(for:) winter (\(newYork.secondsFromGMT(for: winter)))")
    check(newYork.secondsFromGMT(for: summer) == -4 * 3600, "secondsFromGMT(for:) summer (\(newYork.secondsFromGMT(for: summer)))")
    check(!newYork.isDaylightSavingTime(for: winter) && newYork.isDaylightSavingTime(for: summer), "isDaylightSavingTime(for:)")
    check(newYork.daylightSavingTimeOffset(for: summer) == 3600, "daylightSavingTimeOffset(for:)")
    // Darling's -abbreviationForDate: can give the abbreviation for another date, so compare with NSTimeZone.
    let abbreviation = newYork.abbreviation(for: winter)
    check(abbreviation != nil && abbreviation == (newYork as NSTimeZone).abbreviation(for: winter as NSDate),
          "abbreviation(for:) matches NSTimeZone (\(String(describing: abbreviation)))")
    if let transition = newYork.nextDaylightSavingTimeTransition(after: winter) {
        check(transition > winter && transition < summer, "nextDaylightSavingTimeTransition(after:) (\(transition))")
    } else {
        check(false, "nextDaylightSavingTimeTransition(after:)")
    }
    check(newYork == TimeZone(identifier: "America/New_York")! && newYork != TimeZone(identifier: "Europe/Paris")!, "equality")
    check(Set([newYork, TimeZone(identifier: "America/New_York")!, TimeZone(identifier: "Asia/Tokyo")!]).count == 2, "Hashable")
    let ns = newYork as NSTimeZone
    check(ns.name() == "America/New_York", "TimeZone bridges to NSTimeZone")
    check((ns as TimeZone) == newYork, "NSTimeZone bridges back")
    check(newYork.description == "America/New_York (fixed)", "description (\(newYork.description))")
} else {
    check(false, "init(identifier:) America/New_York")
}
check(TimeZone(identifier: "Not/AZone") == nil, "unknown identifier gives nil")

if let plusTwo = TimeZone(secondsFromGMT: 7200) {
    check(plusTwo.secondsFromGMT(for: winter) == 7200 && plusTwo.secondsFromGMT(for: summer) == 7200, "init(secondsFromGMT:) (\(plusTwo.identifier))")
} else {
    check(false, "init(secondsFromGMT:)")
}
check(TimeZone(abbreviation: "GMT")?.secondsFromGMT(for: winter) == 0, "init(abbreviation:)")

let current = TimeZone.current
check(current.identifier == (NSTimeZone.default()?.name() ?? ""), "current matches +[NSTimeZone defaultTimeZone] (\(current.identifier))")
check(current.secondsFromGMT() == (NSTimeZone.default()?.secondsFromGMT() ?? -1), "current secondsFromGMT()")
check((NSTimeZone.system() as TimeZone).identifier == (NSTimeZone.system()?.name() ?? ""), "systemTimeZone bridges without touching +localTimeZone")
// Darling's +localTimeZone dereferences getenv("TZ"), so only exercise autoupdatingCurrent when TZ is set.
if getenv("TZ") != nil {
    check(TimeZone.autoupdatingCurrent == TimeZone.autoupdatingCurrent && TimeZone.autoupdatingCurrent != current, "autoupdatingCurrent equality")
    check((TimeZone.autoupdatingCurrent as NSTimeZone as TimeZone) == TimeZone.autoupdatingCurrent, "autoupdatingCurrent bridges round trip")
} else {
    print("note: TZ is unset, skipping autoupdatingCurrent (Darling's +localTimeZone needs it)")
}

check(TimeZone.knownTimeZoneIdentifiers.contains("Europe/Paris"), "knownTimeZoneIdentifiers (\(TimeZone.knownTimeZoneIdentifiers.count))")
check(!TimeZone.abbreviationDictionary.isEmpty, "abbreviationDictionary (\(TimeZone.abbreviationDictionary.count))")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
