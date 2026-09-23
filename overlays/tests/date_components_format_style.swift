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
let enUS = Locale(identifier: "en_US")
let start = Date(timeIntervalSince1970: 1_678_307_200) // 2023-03-08T20:26:40Z
func after(_ seconds: TimeInterval) -> Range<Date> { start..<start.addingTimeInterval(seconds) }
func style(_ s: Date.ComponentsFormatStyle.Style, _ fields: Set<Date.ComponentsFormatStyle.Field>? = nil, _ locale: Locale = enUS) -> Date.ComponentsFormatStyle {
    Date.ComponentsFormatStyle(style: s, locale: locale, calendar: calendar, fields: fields)
}

let twoTen = after(2 * 3600 + 10 * 60)
check(style(.wide).format(twoTen), "2 hours, 10 minutes", "wide")
check(style(.abbreviated).format(twoTen), "2 hr, 10 min", "abbreviated")
check(style(.condensedAbbreviated).format(twoTen), "2hr 10min", "condensedAbbreviated")
check(style(.narrow).format(twoTen), "2h 10m", "narrow")
check(style(.spellOut).format(twoTen), "two hours, ten minutes", "spellOut")
check(style(.wide, nil, Locale(identifier: "fr_FR")).format(twoTen), "2\u{A0}heures et 10 minutes", "fr_FR wide")
let viaStatic: Date.ComponentsFormatStyle = .components(style: .narrow, fields: [.hour])
check(viaStatic.locale(enUS).calendar(calendar).format(twoTen), "2h", ".components(style:fields:)")

check(style(.wide, [.day, .hour]).format(after(3 * 86400 + 5 * 3600 + 30 * 60)), "3 days, 5 hours", "fields restrict and truncate")
check(style(.wide).format(after(0)), "0 seconds", "zero duration")

let timer = Date.ComponentsFormatStyle.timeDuration.locale(enUS).calendar(calendar)
check(timer.format(after(3600 + 5 * 60 + 3)), "1:05:03", "timeDuration hours")
check(timer.format(after(5 * 60 + 3)), "5:03", "timeDuration minutes")
check(timer.format(after(95)), "1:35", "timeDuration documented example")

var negative = style(.wide)
negative.isPositive = false
check(negative.format(after(2 * 3600)), "-2 hours", "isPositive false")

// The documented example: from exactly one hour, the next outputs are one second either side.
let hour = after(3600)
let wide = style(.wide)
check(wide.format(hour), "1 hour", "one hour")
check(wide.discreteInput(after: hour).map { wide.format($0) }, "1 hour, 1 second", "discreteInput(after:)")
check(wide.discreteInput(before: hour).map { wide.format($0) }, "59 minutes, 59 seconds", "discreteInput(before:)")
check(wide.discreteInput(after: hour)?.lowerBound, start, "positive keeps lowerBound")
let minutes = style(.wide, [.hour, .minute])
check(minutes.discreteInput(after: after(90))?.upperBound, start.addingTimeInterval(120), "next minute bound")

let shrinking = negative.discreteInput(after: hour)
check(shrinking?.upperBound, hour.upperBound, "negative keeps upperBound")
check(shrinking.map { negative.format($0) }, "-59 minutes, -59 seconds", "negative next output")

// Month clamping: Jan 31 plus one month is Feb 28, plus two months is Mar 31.
func utcDate(_ y: Int, _ m: Int, _ d: Int) -> Date { calendar.date(from: DateComponents(year: y, month: m, day: d))! }
let months = style(.wide, [.month])
let clamped = utcDate(2023, 1, 31)..<utcDate(2023, 3, 28)
check(months.format(clamped), "1 month", "clamped month")
let nextMonth = months.discreteInput(after: clamped)
check(nextMonth.map { months.format($0) }, "2 months", "clamped next output")
check(nextMonth.map { abs($0.upperBound.timeIntervalSince(utcDate(2023, 3, 31))) <= 0.001 }, true, "clamped next bound is Mar 31")
let previousMonth = months.discreteInput(before: clamped)
check(previousMonth.map { months.format($0) }, "0 months", "clamped previous output")
check(previousMonth.map { $0.upperBound < utcDate(2023, 2, 28) && $0.upperBound >= utcDate(2023, 2, 28) - 0.002 }, true, "clamped previous bound is just before Feb 28")
check(style(.wide, []).format(twoTen), "", "no fields")

let decoded = try? JSONDecoder().decode(Date.ComponentsFormatStyle.self, from: JSONEncoder().encode(negative))
check(decoded, negative, "Codable round trip")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
