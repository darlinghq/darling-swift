import Foundation

var failures = 0
func check<T: Equatable>(_ actual: T, _ expected: T, _ name: String) {
    if actual != expected {
        print("FAIL: \(name): got \(actual), expected \(expected)")
        failures += 1
    }
}

var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "UTC")!
let now = Date(timeIntervalSince1970: 1_678_307_200) // 2023-03-08T20:26:40Z
let day: TimeInterval = 86400

// Anchored styles describe `anchor` as seen from the input date.
func relative(_ offset: TimeInterval, _ presentation: Date.RelativeFormatStyle.Presentation, _ locale: String,
              _ units: Date.RelativeFormatStyle.UnitsStyle = .wide) -> String {
    Date.AnchoredRelativeFormatStyle(anchor: now.addingTimeInterval(offset), presentation: presentation, unitsStyle: units,
                                     locale: Locale(identifier: locale), calendar: calendar).format(now)
}

check(relative(-day, .named, "en_US"), "yesterday", "en_US named -1 day")
check(relative(-day, .numeric, "en_US"), "1 day ago", "en_US numeric -1 day")
check(relative(day, .named, "en_US"), "tomorrow", "en_US named +1 day")
check(relative(day, .numeric, "en_US"), "in 1 day", "en_US numeric +1 day")
check(relative(-day, .named, "fr_FR"), "hier", "fr_FR named")
check(relative(-day, .numeric, "fr_FR"), "il y a 1 jour", "fr_FR numeric")
check(relative(-day, .named, "ja_JP"), "昨日", "ja_JP named")
check(relative(-day, .numeric, "ja_JP"), "1 日前", "ja_JP numeric")
check(relative(-3 * day, .named, "en_US"), "3 days ago", "no named form for 3 days")
check(relative(-3600, .numeric, "en_US"), "1 hour ago", "hours")
check(relative(-3600, .numeric, "en_US", .abbreviated), "1 hr. ago", "abbreviated units")
check(relative(-2 * day, .numeric, "en_US", .spellOut), "two days ago", "spelled-out units")

var capitalized = Date.AnchoredRelativeFormatStyle(anchor: now - day, presentation: .named, locale: Locale(identifier: "en_US"), calendar: calendar)
capitalized.capitalizationContext = .beginningOfSentence
check(capitalized.format(now), "Yesterday", "capitalization context")

// Relative output rounds to the nearest unit, so the next change is within a minute.
let minutesAgo = Date.AnchoredRelativeFormatStyle(anchor: now - 120, presentation: .numeric, locale: Locale(identifier: "en_US"), calendar: calendar)
check(minutesAgo.format(now), "2 minutes ago", "minutes")
if let next = minutesAgo.discreteInput(after: now) {
    check(minutesAgo.format(next), "3 minutes ago", "discreteInput(after:) reaches the next output")
    check(next > now && next <= now + 60, true, "discreteInput(after:) is within a minute")
} else {
    check(false, true, "discreteInput(after:) returned nil")
}

check(Date.RelativeFormatStyle(presentation: .named, locale: Locale(identifier: "en_US"), calendar: calendar).format(Date.now - day), "yesterday", "RelativeFormatStyle against now")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
