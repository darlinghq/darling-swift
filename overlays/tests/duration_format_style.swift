import Foundation

var failures = 0
func check<T: Equatable>(_ actual: T, _ expected: T, _ name: String) {
    if actual != expected {
        print("FAIL: \(name): got \(actual), expected \(expected)")
        failures += 1
    }
}

let enUS = Locale(identifier: "en_US")
let d = Duration.seconds(3725) // 1 h 2 min 5 s
let hms: Set<Duration.UnitsFormatStyle.Unit> = [.hours, .minutes, .seconds]

check(d.formatted(.units(allowed: hms, width: .wide).locale(enUS)), "1 hour, 2 minutes, 5 seconds", "units wide")
check(d.formatted(.units(allowed: hms, width: .abbreviated).locale(enUS)), "1 hr, 2 min, 5 sec", "units abbreviated")
check(d.formatted(.units(allowed: hms, width: .narrow).locale(enUS)), "1h 2m 5s", "units narrow")
check(d.formatted(.units(allowed: [.minutes], width: .wide).locale(enUS)), "62 minutes", "units restricted")
check(Duration.milliseconds(1500).formatted(.units(allowed: [.seconds], width: .abbreviated, fractionalPart: .show(length: 1)).locale(enUS)), "1.5 sec", "fractional part")
check(Duration.zero.formatted(.units(allowed: hms, width: .wide, zeroValueUnits: .show(length: 1)).locale(enUS)), "0 hours, 0 minutes, 0 seconds", "zero units shown")
check(d.formatted(.units(allowed: hms, width: .wide).locale(Locale(identifier: "de_DE"))), "1 Stunde, 2 Minuten und 5 Sekunden", "de_DE units")

check(d.formatted(.time(pattern: .hourMinuteSecond).locale(enUS)), "1:02:05", "time h:mm:ss")
check(d.formatted(.time(pattern: .minuteSecond).locale(enUS)), "62:05", "time mm:ss")
check(d.formatted(.time(pattern: .hourMinute).locale(enUS)), "1:02", "time h:mm")
check(Duration.milliseconds(3725_250).formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 2, fractionalSecondsLength: 2)).locale(enUS)), "01:02:05.25", "time padding and fraction")

// Attributed output tags each unit.
let attributed = d.formatted(Duration.UnitsFormatStyle(allowedUnits: hms, width: .wide).locale(enUS).attributed)
check(String(attributed.characters), "1 hour, 2 minutes, 5 seconds", "attributed text")
func fieldRuns(_ s: AttributedString) -> [String] {
    s.runs.compactMap { run in
        run.durationField.map { "\(String(s[run.range].characters))=\($0)\(run.measurement.map { "/\($0)" } ?? "")" }
    }
}
check(fieldRuns(attributed), ["1=hours/value", " =hours", "hour=hours/unit", "2=minutes/value", " =minutes", "minutes=minutes/unit",
                              "5=seconds/value", " =seconds", "seconds=seconds/unit"], "units attributed runs")
let attributedTime = d.formatted(Duration.TimeFormatStyle(pattern: .hourMinuteSecond, locale: enUS).attributed)
check(fieldRuns(attributedTime), ["1=hours", "02=minutes", "05=seconds"], "time attributed runs")

// Discrete bounds follow the smallest displayed unit.
let time = Duration.TimeFormatStyle(pattern: .hourMinuteSecond, locale: enUS)
// Seconds round half-even, so "1:02:05" becomes "1:02:06" at 3725.5 s.
check(time.discreteInput(after: d), .milliseconds(3_725_500), "time discreteInput(after:)")
let units = Duration.UnitsFormatStyle(allowedUnits: [.hours, .minutes], width: .wide).locale(enUS)
if let next = units.discreteInput(after: d) {
    check(units.format(next) != units.format(d), true, "units discreteInput(after:) changes output")
    check(next <= .seconds(3780), true, "units next bound within the minute")
} else {
    check(false, true, "units discreteInput(after:) returned nil")
}

// Number formatting underneath: BinaryInteger.formatted() and friends.
check(1234567.formatted(.number.locale(enUS)), "1,234,567", "Int en_US")
check(1234567.formatted(.number.locale(Locale(identifier: "de_DE"))), "1.234.567", "Int de_DE")
check((-42).formatted(.number.locale(enUS)), "-42", "negative Int")
check(Int64.max.formatted(.number.locale(enUS)), "9,223,372,036,854,775,807", "Int64.max")
check(UInt64.max.formatted(.number.locale(enUS)), "18,446,744,073,709,551,615", "UInt64.max")
check(1234567.formatted(), IntegerFormatStyle<Int>(locale: .autoupdatingCurrent).format(1234567), "BinaryInteger.formatted()")
check(3.14159.formatted(.number.precision(.fractionLength(2)).locale(enUS)), "3.14", "Double precision")
// Percent skeletons carry a Decimal scale, which needs darling-foundation#57's NSDecimalString.
check(0.256.formatted(.percent.locale(enUS)), "25.6%", "percent")
check(Decimal(string: "1234.5")!.formatted(.number.locale(enUS)), "1,234.5", "Decimal.FormatStyle")
check(try? Int("1,234", format: .number.locale(enUS)), 1234, "IntegerParseStrategy")
check(try? Double("1,234.5", format: .number.locale(enUS)), 1234.5, "FloatingPointParseStrategy")
check(try? Decimal("1,234.5", format: .number.locale(enUS)), Decimal(string: "1234.5"), "Decimal.ParseStrategy")
check(Int64(1_500_000).formatted(.byteCount(style: .decimal).locale(enUS)), "1.5 MB", "ByteCountFormatStyle")

let narrowUnits = Duration.UnitsFormatStyle(allowedUnits: [.hours, .minutes], width: .narrow).locale(enUS)
check(try? JSONDecoder().decode(Duration.UnitsFormatStyle.self, from: JSONEncoder().encode(narrowUnits)), narrowUnits, "UnitsFormatStyle Codable round trip")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
