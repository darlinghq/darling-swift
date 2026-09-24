import Foundation

var failures = 0
func check<T: Equatable>(_ actual: T, _ expected: T, _ name: String) {
    if actual != expected {
        print("FAIL: \(name): got \(actual), expected \(expected)")
        failures += 1
    }
}

// 2023-03-08T20:26:40Z, a Wednesday in ISO week 10.
let instant = Date(timeIntervalSince1970: 1_678_307_200)
let plus0530 = TimeZone(secondsFromGMT: 5 * 3600 + 1800)!
let minus0300 = TimeZone(secondsFromGMT: -3 * 3600)!

// Darling's CoreFoundation has no ISO 8601 calendar; the Gregorian stand-in must use ISO weeks.
let isoCalendar = Calendar(identifier: .iso8601)
check(isoCalendar.firstWeekday, 2, "ISO 8601 calendar starts weeks on Monday")
check(isoCalendar.minimumDaysInFirstWeek, 4, "ISO 8601 calendar week 1 has 4 days")

// Formatting.
check(instant.ISO8601Format(), "2023-03-08T20:26:40Z", "ISO8601Format() default")
check(instant.formatted(.iso8601), "2023-03-08T20:26:40Z", ".iso8601")
check(Date.ISO8601FormatStyle().dateSeparator(.omitted).timeSeparator(.omitted).timeZoneSeparator(.omitted).format(instant), "20230308T202640Z", "omitted separators")
check(Date.ISO8601FormatStyle(dateTimeSeparator: .space).format(instant), "2023-03-08 20:26:40Z", "space date-time separator")
check(Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(instant.addingTimeInterval(0.125)), "2023-03-08T20:26:40.125Z", "fractional seconds")
check(Date.ISO8601FormatStyle(timeZone: plus0530).format(instant), "2023-03-09T01:56:40+0530", "positive offset")
check(Date.ISO8601FormatStyle(timeZoneSeparator: .colon, timeZone: plus0530).format(instant), "2023-03-09T01:56:40+05:30", "offset with colon")
check(Date.ISO8601FormatStyle(timeZone: minus0300).format(instant), "2023-03-08T17:26:40-0300", "negative offset")
check(Date.ISO8601FormatStyle(timeZone: TimeZone(identifier: "America/New_York")!).format(instant), "2023-03-08T15:26:40-0500", "named zone")
check(Date.ISO8601FormatStyle(timeZone: TimeZone(identifier: "America/New_York")!).format(Date(timeIntervalSince1970: 1_689_000_000)), "2023-07-10T10:40:00-0400", "named zone in DST")
check(Date.ISO8601FormatStyle().year().month().day().format(instant), "2023-03-08", "date only")
check(Date.ISO8601FormatStyle().time(includingFractionalSeconds: false).format(instant), "20:26:40", "time only")
check(Date.ISO8601FormatStyle().year().weekOfYear().day().format(instant), "2023-W10-03", "week of year")
// 2021-01-01 is the Friday of ISO week 53 of 2020.
check(Date.ISO8601FormatStyle().year().weekOfYear().day().format(Date(timeIntervalSince1970: 1_609_459_200)), "2020-W53-05", "week of year across a year boundary")
check(Date.ISO8601FormatStyle().year().day().format(instant), "2023-067", "ordinal date")
check(Date.ISO8601FormatStyle().year().day().dateSeparator(.omitted).format(Date(timeIntervalSince1970: 1_703_980_800)), "2023365", "ordinal date, last day")

// Parsing.
let style = Date.ISO8601FormatStyle()
check(try? style.parse("2023-03-08T20:26:40Z"), instant, "parse default")
check(try? Date("2023-03-08T20:26:40Z", strategy: .iso8601), instant, "Date(_:strategy: .iso8601)")
check(try? style.parse("2023-03-09T01:56:40+05:30"), instant, "parse offset with colon")
check(try? style.parse("2023-03-08T17:26:40-0300"), instant, "parse negative offset")
check(try? style.parse("2023-03-08T20:26:40.125Z"), instant.addingTimeInterval(0.125), "parse fractional seconds")
let omitted = style.dateSeparator(.omitted).timeSeparator(.omitted)
check(try? omitted.parse(omitted.format(instant)), instant, "round trip omitted separators")
let week = style.year().weekOfYear().day()
check(try? week.parse("2020-W53-05"), Date(timeIntervalSince1970: 1_609_459_200), "parse week of year")
let ordinal = style.year().day()
check(try? ordinal.parse("2023-067"), Date(timeIntervalSince1970: 1_678_233_600), "parse ordinal date")
let newYork = TimeZone(identifier: "America/New_York")!
let ordinalTime = Date.ISO8601FormatStyle(timeZone: newYork).year().day().time(includingFractionalSeconds: false).timeZone(separator: .colon)
check(ordinalTime.format(Date(timeIntervalSince1970: 1_689_000_000)), "2023-191T10:40:00-04:00", "ordinal date and time in DST")
check(try? ordinalTime.parse("2023-191T10:40:00-04:00"), Date(timeIntervalSince1970: 1_689_000_000), "parse ordinal date and time in DST")
check(try? Date.ISO8601FormatStyle(timeZone: newYork).year().day().time(includingFractionalSeconds: false).parse("2023-191T10:40:00"), Date(timeIntervalSince1970: 1_689_000_000), "parse ordinal date in the style's DST zone")
for zone in [TimeZone.gmt, plus0530, minus0300, TimeZone(identifier: "Europe/Paris")!] {
    let s = Date.ISO8601FormatStyle(includingFractionalSeconds: true, timeZone: zone)
    check(try? s.parse(s.format(instant)), instant, "round trip in \(zone.identifier)")
}

// Parse failures throw a formatting error.
for bad in ["", "not a date", "2023-13-08T20:26:40Z", "2023-03-08T20:26:40", "2023-03-08X20:26:40Z", "2020-W54-01"] {
    let parser = bad.hasPrefix("2020-W") ? week : style
    do {
        let date = try parser.parse(bad)
        print("FAIL: parse \"\(bad)\" gave \(date)")
        failures += 1
    } catch let error as CocoaError {
        check(error.code, .formatting, "error code for \"\(bad)\"")
    } catch {
        print("FAIL: parse \"\(bad)\" threw \(error)")
        failures += 1
    }
}

// DateComponents.ISO8601FormatStyle.
let components = try? DateComponents.ISO8601FormatStyle().parse("2023-03-08T21:26:40+0100")
check(components?.year, 2023, "components year")
check(components?.month, 3, "components month")
check(components?.day, 8, "components day")
check(components?.hour, 21, "components hour")
check(components?.timeZone?.secondsFromGMT(), 3600, "components time zone")
check(DateComponents.ISO8601FormatStyle().format(DateComponents(year: 2023, month: 3, day: 8, hour: 20, minute: 26, second: 40)), "2023-03-08T20:26:40Z", "format components")
check(DateComponents.ISO8601FormatStyle(timeZone: newYork).format(DateComponents(year: 2023, month: 7, day: 10, hour: 10, minute: 40)), "2023-07-10T10:40:00-0400", "format components in a named zone")

// Regex components.
check("logged 2023-03-08T20:26:40Z ok".firstMatch(of: Date.ISO8601FormatStyle())?.output, instant, "regex component")
check("at 2023-03-08T20:26:40.125+0000".firstMatch(of: .iso8601WithTimeZone(includingFractionalSeconds: true))?.output, instant.addingTimeInterval(0.125), "iso8601WithTimeZone")
check("2023-03-08".firstMatch(of: .iso8601Date(timeZone: .gmt))?.output, Date(timeIntervalSince1970: 1_678_233_600), "iso8601Date")

// OpenSwiftUI's size-adaptive and time-zone-dependent format styles.
let compact = Date.ISO8601FormatStyle().dateSeparator(.omitted).timeSeparator(.omitted).timeZoneSeparator(.omitted)
check(compact == Date.ISO8601FormatStyle(dateSeparator: .omitted, timeSeparator: .omitted), true, "equal styles")
check(compact == Date.ISO8601FormatStyle(), false, "different styles")
var zoned = compact
zoned.timeZone = plus0530
check(zoned.timeZone, plus0530, "timeZone setter")
check(zoned == compact, false, "time zone takes part in equality")
check(zoned.format(instant), "20230309T015640+0530", "compact style in a time zone")
check(Set([compact, compact, zoned]).count, 2, "hashable")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
