import Foundation

var failures = 0
func check<T: Equatable>(_ actual: T, _ expected: T, _ name: String) {
    if actual != expected {
        print("FAIL: \(name): got \(actual), expected \(expected)")
        failures += 1
    }
}

// 2023-03-08T20:26:40Z
let instant = Date(timeIntervalSince1970: 1_678_307_200)
let utc = TimeZone(identifier: "UTC")!
let gregorian = Calendar(identifier: .gregorian)
func style(_ locale: String, _ tz: TimeZone = utc) -> Date.FormatStyle {
    Date.FormatStyle(locale: Locale(identifier: locale), calendar: gregorian, timeZone: tz)
}

check(style("en_US").year().month(.wide).day().format(instant), "March 8, 2023", "en_US yMMMMd")
check(Date.FormatStyle(date: .abbreviated, time: .omitted, locale: Locale(identifier: "en_US"), calendar: gregorian, timeZone: utc).format(instant), "Mar 8, 2023", "en_US abbreviated date")
check(style("en_US").hour().minute().format(instant), "8:26 PM", "en_US hmm")
check(style("en_US").hour(.twoDigits(amPM: .abbreviated)).minute().format(instant), "08:26 PM", "en_US hhmm keeps field length")
check(style("ja_JP").year().month().day().format(instant), "2023年3月8日", "ja_JP yMMMd")
check(style("fr_FR", TimeZone(identifier: "Europe/Paris")!).year().month(.wide).day().format(instant), "8 mars 2023", "fr_FR Europe/Paris")
check(instant.formatted(style("en_US").year().month().day()), "Mar 8, 2023", "Date.formatted(_:)")
check(Date.FormatStyle(locale: Locale(identifier: "en_US"), calendar: Calendar(identifier: .buddhist), timeZone: utc).year().format(instant), "2566 BE", "calendar keyword reaches ICU")

// Attributed output tags each field.
let attributed = style("en_US").year().month(.wide).day().attributedStyle.format(instant)
check(String(attributed.characters), "March 8, 2023", "attributed text")
var fields: [String] = []
for run in attributed.runs {
    if let field = run.foundation.dateField {
        fields.append("\(String(attributed[run.range].characters))=\(field)")
    }
}
check(fields, ["March=month", "8=day", "2023=year"], "attributed fields")

// Discrete bounds follow the smallest displayed field.
let minutes = style("en_US").hour().minute()
check(minutes.discreteInput(after: instant), Date(timeIntervalSince1970: 1_678_307_220), "next minute bound")
let before = minutes.discreteInput(before: instant)!
check(before < Date(timeIntervalSince1970: 1_678_307_160) && before > Date(timeIntervalSince1970: 1_678_307_159.999), true, "previous minute bound")

// Parsing inverts formatting.
check(try? style("en_US").year().month().day().parse("Mar 8, 2023"), Date(timeIntervalSince1970: 1_678_233_600), "parse")

// Verbatim patterns are used as given.
let verbatim = Date.VerbatimFormatStyle(format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits) \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits)", timeZone: utc, calendar: gregorian)
check(verbatim.format(instant), "2023-03-08 20:26", "verbatim")
check(verbatim.discreteInput(after: instant), Date(timeIntervalSince1970: 1_678_307_220), "verbatim next minute bound")
check(String(verbatim.attributedStyle.format(instant).characters), "2023-03-08 20:26", "verbatim attributed")

check(Locale(identifier: "en_US").hourCycle, .oneToTwelve, "en_US hour cycle")
check(Locale(identifier: "de_DE").hourCycle, .zeroToTwentyThree, "de_DE hour cycle")
check(Locale(identifier: "en_US@hours=h23").hourCycle, .zeroToTwentyThree, "hours keyword")
check(Locale(identifier: "en_US@rg=gbzzzz").hourCycle, .zeroToTwentyThree, "rg region override")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
