// Calendar, DateComponents and DateInterval through the Foundation overlay, under Darling.
import Foundation

// Unbuffered, so a crash still shows the last passing check.
setvbuf(stdout, nil, _IONBF, 0)

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

let utc = TimeZone(identifier: "UTC")!
var gregorian = Calendar(identifier: .gregorian)
gregorian.timeZone = utc

// 2021-01-15 12:00:00 UTC (Friday) and 2021-07-15 12:00:00 UTC (Thursday)
let winter = Date(timeIntervalSince1970: 1610712000)
let summer = Date(timeIntervalSince1970: 1626350400)
func utcDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
    return gregorian.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

// Calendar basics
check(gregorian.identifier == .gregorian, "identifier (\(gregorian.identifier))")
check(gregorian.timeZone == utc, "timeZone setter (\(gregorian.timeZone.identifier))")
check(gregorian.date(from: DateComponents(year: 2021, month: 7, day: 15, hour: 12)) == summer, "date(from:)")
let parts = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .weekday], from: summer)
check(parts.year == 2021 && parts.month == 7 && parts.day == 15 && parts.hour == 12 && parts.minute == 0 && parts.weekday == 5,
      "dateComponents(_:from:) (\(parts))")
check(parts.second == nil && parts.era == nil, "unrequested components are nil")
check(gregorian.component(.day, from: summer) == 15, "component(_:from:)")
check(gregorian.date(byAdding: .day, value: 20, to: summer) == utcDate(2021, 8, 4, 12), "date(byAdding:value:to:)")
check(gregorian.date(byAdding: DateComponents(month: 1, day: 1), to: summer) == utcDate(2021, 8, 16, 12), "date(byAdding: DateComponents)")
check(gregorian.dateComponents([.day], from: winter, to: summer).day == 181, "dateComponents(_:from:to:)")
check(gregorian.dateComponents([.month], from: DateComponents(year: 2021, month: 1), to: DateComponents(year: 2021, month: 7)).month == 6,
      "dateComponents(_:from: DateComponents, to:)")
check(gregorian.startOfDay(for: summer) == utcDate(2021, 7, 15), "startOfDay(for:)")
if let month = gregorian.dateInterval(of: .month, for: summer) {
    check(month.start == utcDate(2021, 7, 1) && month.duration == 31 * 86400, "dateInterval(of: .month) (\(month))")
} else {
    check(false, "dateInterval(of: .month)")
}
check(gregorian.range(of: .day, in: .month, for: utcDate(2021, 2, 10)) == 1..<29, "range(of:in:for:)")
check(gregorian.ordinality(of: .day, in: .year, for: summer) == 196, "ordinality(of:in:for:)")
check(gregorian.maximumRange(of: .hour) == 0..<24, "maximumRange(of:)")
var weeks = gregorian
weeks.firstWeekday = 1
weeks.minimumDaysInFirstWeek = 1
check(weeks.range(of: .weekOfMonth, in: .month, for: summer) == 1..<6,
      "range(of: .weekOfMonth, in: .month) (\(String(describing: weeks.range(of: .weekOfMonth, in: .month, for: summer))))")
check(gregorian.range(of: .weekday, in: .weekOfYear, for: summer) == 1..<8, "range(of: .weekday, in: .weekOfYear)")
check(gregorian.range(of: .era, in: .hour, for: summer) == nil, "unsupported ranges are nil")

// Quarters
check(gregorian.dateComponents([.quarter], from: utcDate(2021, 11, 10)).quarter == 4, "quarter from month")
check(gregorian.maximumRange(of: .quarter) == 1..<5 && gregorian.range(of: .quarter, in: .year, for: summer) == 1..<5, "quarter ranges")
check(gregorian.range(of: .month, in: .quarter, for: summer) == 7..<10, "range(of: .month, in: .quarter)")
check(gregorian.ordinality(of: .quarter, in: .year, for: summer) == 3 && gregorian.ordinality(of: .month, in: .quarter, for: summer) == 1,
      "quarter ordinality")
check(gregorian.maximumRange(of: .nanosecond) == 0..<1_000_000_000 && gregorian.minimumRange(of: .timeZone) == nil,
      "ranges of units without calendar fields")
check(gregorian.range(of: .calendar, in: .year, for: summer) == nil && gregorian.ordinality(of: .nanosecond, in: .second, for: summer) == nil
      && gregorian.dateInterval(of: .timeZone, for: summer) == nil, "calendar/timeZone/nanosecond ranges are nil")
check(gregorian.date(byAdding: .quarter, value: 1, to: utcDate(2021, 1, 5, 12)) == utcDate(2021, 4, 5, 12), "date(byAdding: .quarter)")
check(gregorian.isDate(utcDate(2021, 1, 5), equalTo: utcDate(2021, 2, 10), toGranularity: .quarter)
      && !gregorian.isDate(utcDate(2021, 3, 31), equalTo: utcDate(2021, 4, 1), toGranularity: .quarter), "compare(toGranularity: .quarter)")

// Comparisons
check(gregorian.isDate(summer, inSameDayAs: summer.addingTimeInterval(3600)), "isDate(_:inSameDayAs:)")
check(!gregorian.isDate(summer, inSameDayAs: summer.addingTimeInterval(86400)), "isDate(_:inSameDayAs:) next day")
check(gregorian.compare(summer, to: summer.addingTimeInterval(60), toGranularity: .hour) == .orderedSame, "compare(toGranularity: .hour)")
check(gregorian.compare(summer, to: summer.addingTimeInterval(60), toGranularity: .minute) == .orderedAscending, "compare(toGranularity: .minute)")
check(gregorian.isDate(winter, equalTo: utcDate(2021, 1, 2), toGranularity: .month), "isDate(_:equalTo:toGranularity:)")
check(gregorian.isDateInToday(Date()), "isDateInToday")
check(gregorian.isDateInYesterday(gregorian.date(byAdding: .day, value: -1, to: Date())!), "isDateInYesterday")
check(gregorian.isDateInTomorrow(gregorian.date(byAdding: .day, value: 1, to: Date())!), "isDateInTomorrow")
check(gregorian.isDateInWeekend(utcDate(2021, 7, 17)) && !gregorian.isDateInWeekend(summer), "isDateInWeekend")

// Searching
check(gregorian.nextDate(after: summer, matching: DateComponents(hour: 9, minute: 30), matchingPolicy: .nextTime) == utcDate(2021, 7, 16, 9, 30),
      "nextDate hour/minute")
check(gregorian.nextDate(after: summer, matching: DateComponents(weekday: 2), matchingPolicy: .nextTime) == utcDate(2021, 7, 19),
      "nextDate weekday")
check(gregorian.nextDate(after: summer, matching: DateComponents(month: 2, day: 29), matchingPolicy: .strict) == utcDate(2024, 2, 29),
      "nextDate leap day")
check(gregorian.nextDate(after: summer, matching: DateComponents(hour: 9), matchingPolicy: .nextTime, direction: .backward) == utcDate(2021, 7, 15, 9),
      "nextDate backward")
check(gregorian.nextDate(after: utcDate(2021, 7, 15, 9, 30), matching: DateComponents(hour: 9), matchingPolicy: .nextTime, direction: .backward) == utcDate(2021, 7, 15, 9),
      "nextDate backward from inside the matching hour")
check(gregorian.nextDate(after: summer, matching: DateComponents(hour: 25), matchingPolicy: .strict) == nil, "nextDate impossible")
check(gregorian.nextDate(after: summer, matching: DateComponents(quarter: 2), matchingPolicy: .nextTime) == utcDate(2022, 4, 1), "nextDate quarter")
check(gregorian.nextDate(after: summer, matching: DateComponents(year: 2020), matchingPolicy: .strict) == nil, "nextDate for a past year")
check(gregorian.nextDate(after: summer, matching: DateComponents(month: 2, day: 30), matchingPolicy: .strict) == nil, "nextDate for February 30")
var iso = gregorian
iso.firstWeekday = 2
iso.minimumDaysInFirstWeek = 4
check(iso.nextDate(after: utcDate(2020, 6, 1), matching: DateComponents(weekOfYear: 1, yearForWeekOfYear: 2021), matchingPolicy: .nextTime) == utcDate(2021, 1, 4),
      "nextDate week-based year (\(String(describing: iso.nextDate(after: utcDate(2020, 6, 1), matching: DateComponents(weekOfYear: 1, yearForWeekOfYear: 2021), matchingPolicy: .nextTime))))")
var quarters: [Date] = []
gregorian.enumerateDates(startingAfter: utcDate(2020, 1, 15), matching: DateComponents(quarter: 2), matchingPolicy: .nextTime) { date, _, stop in
    if let date = date { quarters.append(date) }
    if quarters.count == 3 { stop = true }
}
check(quarters == [utcDate(2020, 4, 1), utcDate(2021, 4, 1), utcDate(2022, 4, 1)], "enumerateDates quarter gives one date per quarter (\(quarters))")
check(gregorian.nextDate(after: utcDate(2021, 5, 10), matching: DateComponents(quarter: 2), matchingPolicy: .nextTime) == utcDate(2022, 4, 1),
      "nextDate quarter from inside a matching quarter")
check(gregorian.nextDate(after: utcDate(2021, 5, 10), matching: DateComponents(quarter: 2), matchingPolicy: .nextTime, direction: .backward) == utcDate(2021, 4, 1),
      "nextDate quarter backward from inside a matching quarter")
if let week10 = iso.nextDate(after: utcDate(2021, 1, 1), matching: DateComponents(weekOfYear: 10), matchingPolicy: .nextTime) {
    check(week10 == utcDate(2021, 3, 8), "nextDate weekOfYear (\(week10))")
    check(iso.nextDate(after: week10, matching: DateComponents(weekOfYear: 10), matchingPolicy: .nextTime) == utcDate(2022, 3, 7),
          "nextDate weekOfYear from inside the matching week")
} else {
    check(false, "nextDate weekOfYear")
}
check(gregorian.nextDate(after: summer, matching: DateComponents(year: 2023, month: 2, day: 29), matchingPolicy: .strict) == nil,
      "nextDate for a year without the date ends")
check(gregorian.nextDate(after: summer, matching: DateComponents(year: 2020, month: 2, day: 29), matchingPolicy: .strict, direction: .backward) == utcDate(2020, 2, 29),
      "nextDate backward to a past leap day")
var newYork = Calendar(identifier: .gregorian)
newYork.timeZone = TimeZone(identifier: "America/New_York")!
// 2021-11-07 00:30 EDT; clocks go back from 02:00 EDT to 01:00 EST.
let beforeFallBack = Date(timeIntervalSince1970: 1636259400)
let firstOne = newYork.nextDate(after: beforeFallBack, matching: DateComponents(hour: 1), matchingPolicy: .nextTime)
check(firstOne == Date(timeIntervalSince1970: 1636261200), "nextDate hour before a repeated hour (\(String(describing: firstOne)))")
check(firstOne.flatMap { newYork.nextDate(after: $0, matching: DateComponents(hour: 1), matchingPolicy: .nextTime) } == Date(timeIntervalSince1970: 1636351200),
      "nextDate skips the repeated hour")
var saoPaulo = Calendar(identifier: .gregorian)
saoPaulo.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
// DST started at midnight on Sunday 2018-11-04, so that day begins at 01:00 (03:00 UTC).
var sundays: [Date] = []
saoPaulo.enumerateDates(startingAfter: Date(timeIntervalSince1970: 1541030400), matching: DateComponents(weekday: 1), matchingPolicy: .nextTime) { date, _, stop in
    if let date = date { sundays.append(date) }
    if sundays.count == 2 { stop = true }
}
check(sundays == [Date(timeIntervalSince1970: 1541300400), Date(timeIntervalSince1970: 1541901600)],
      "day search doesn't drift after a day without midnight (\(sundays.map { $0.timeIntervalSince1970 }))")
var hours: [Date] = []
gregorian.enumerateDates(startingAfter: summer, matching: DateComponents(minute: 0), matchingPolicy: .nextTime) { date, exact, stop in
    if let date = date, exact { hours.append(date) }
    if hours.count == 3 { stop = true }
}
check(hours == [utcDate(2021, 7, 15, 13), utcDate(2021, 7, 15, 14), utcDate(2021, 7, 15, 15)], "enumerateDates (\(hours))")
check(gregorian.date(bySettingHour: 18, minute: 45, second: 0, of: summer) == utcDate(2021, 7, 15, 18, 45), "date(bySettingHour:minute:second:of:)")
check(gregorian.date(bySetting: .hour, value: 20, of: summer) == utcDate(2021, 7, 15, 20), "date(bySetting:value:of:)")
check(gregorian.date(summer, matchesComponents: DateComponents(month: 7, day: 15)), "date(_:matchesComponents:)")

// Symbols, compared with NSDateFormatter since Darling's CFDateFormatter provides them
let formatter = NSDateFormatter()!
formatter.calendar = gregorian as NSCalendar
let objcWeekdays = (formatter.weekdaySymbols() ?? []).compactMap { $0 as? String }
check(gregorian.weekdaySymbols == objcWeekdays, "weekdaySymbols matches NSDateFormatter (\(gregorian.weekdaySymbols))")

// Value semantics, equality and bridging
var copy = gregorian
copy.firstWeekday = 2
check(gregorian.firstWeekday != 2 && copy.firstWeekday == 2, "copy on write")
check(copy != gregorian && Calendar(identifier: .gregorian) == Calendar(identifier: .gregorian), "equality")
let bridged = gregorian as NSCalendar
check((bridged as Calendar) == gregorian && (bridged as Calendar).timeZone == utc, "NSCalendar bridging keeps the time zone")
check(Calendar.current.identifier == ((NSCalendar.currentCalendar() as! NSCalendar) as Calendar).identifier,
      "current matches +[NSCalendar currentCalendar] (\(Calendar.current.identifier))")
check(Calendar.autoupdatingCurrent == Calendar.autoupdatingCurrent && (Calendar.autoupdatingCurrent as NSCalendar as Calendar) == Calendar.autoupdatingCurrent,
      "autoupdatingCurrent equality and bridging")
check(Set([gregorian, gregorian, copy]).count == 2, "Hashable")
check(Locale(identifier: "en_US").calendar.identifier == .gregorian, "Locale.calendar")
check(Locale(identifier: "th_TH").calendar.identifier == .buddhist, "Locale.calendar for th_TH (\(Locale(identifier: "th_TH").calendar.identifier))")
let buddhistName = Locale(identifier: "en").localizedString(for: .buddhist)
check(!(buddhistName ?? "").isEmpty, "localizedString(for: Calendar.Identifier) (\(String(describing: buddhistName)))")

// DateComponents
var components = DateComponents(calendar: gregorian, timeZone: utc, year: 2021, month: 7, day: 15, hour: 12, nanosecond: 5_000_000)
components.weekOfMonth = 3
// Darling composes nanoseconds as milliseconds, so allow for floating-point rounding.
check(components.date.map { abs($0.timeIntervalSince(summer) - 0.005) < 0.0005 } ?? false,
      "DateComponents.date (\(String(describing: components.date?.timeIntervalSince1970)))")
check(components.value(for: .month) == 7, "value(for:)")
components.setValue(8, for: .month)
check(components.month == 8, "setValue(_:for:)")
check(components == components && components != DateComponents(year: 2021), "DateComponents equality")
check(Set([components, components]).count == 1, "DateComponents Hashable")
let roundTrip = components as NSDateComponents as DateComponents
check(roundTrip.year == 2021 && roundTrip.month == 8 && roundTrip.weekOfMonth == 3 && roundTrip.nanosecond == 5_000_000 && roundTrip.hour == 12,
      "NSDateComponents bridging (\(roundTrip))")
check(roundTrip.timeZone == utc && roundTrip.calendar?.identifier == .gregorian, "bridging keeps calendar and time zone")
check(DateComponents(calendar: gregorian, year: 2021, month: 2, day: 28).isValidDate, "isValidDate")
check(!DateComponents(calendar: gregorian, year: 2021, month: 2, day: 30).isValidDate, "isValidDate for Feb 30")

// DateInterval
let interval = DateInterval(start: winter, end: summer)
check(interval.contains(utcDate(2021, 3, 1)) && !interval.contains(utcDate(2022, 1, 1)), "DateInterval.contains")
check(interval.start == winter && interval.end == summer && interval.duration == summer.timeIntervalSince(winter), "DateInterval start/end")
check(interval.intersection(with: DateInterval(start: summer, duration: 10)) == DateInterval(start: summer, duration: 0), "DateInterval.intersection")
check(!interval.description.isEmpty, "DateInterval.description (\(interval))")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
