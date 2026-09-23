// Written for Darling: the swift-foundation Locale and Calendar internals its fetched format styles
// call, over this overlay's NSLocale/NSCalendar-backed types. Copied pieces name their source file (Apache 2.0).

internal import _FoundationICU
internal import os

// From FormatParsingUtilities.swift; the rest of that file needs BufferView.
func parseError(_ value: String, exampleFormattedString: String?, extendedDescription: String? = nil) -> CocoaError {
    let errorStr: String
    if let exampleFormattedString = exampleFormattedString {
        errorStr = "Cannot parse \(value)\(extendedDescription.map({ ": \($0)." }) ?? ".") String should adhere to the preferred format of the locale, such as \(exampleFormattedString)."
    } else {
        errorStr = "Cannot parse \(value)\(extendedDescription.map({ ": \($0)." }) ?? ".")"
    }
    return CocoaError(CocoaError.formatting, userInfo: [ NSDebugDescriptionErrorKey: errorStr ])
}

extension Locale {
    // Darling's Locale has no per-user preference overrides to capture or force.
    var identifierCapturingPreferences: String { identifier }

    func forceFirstWeekday(_ calendar: Calendar.Identifier) -> Locale.Weekday? { nil }

    // `hours` keyword, then `rg` region override, then locale data, as Locale_ICU consults them.
    @available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
    public var hourCycle: HourCycle {
        if let value = Locale.keywordValue(identifier, HourCycle.legacyKeywordKey.key), let hc = HourCycle(rawValue: value) {
            return hc
        }
        var patternLocale = identifier
        // An `rg` value is a subdivision id such as "gbzzzz"; its first two letters are the region.
        if let rg = Locale.keywordValue(identifier, Region.legacyKeywordKey.key), rg.count > 2 {
            patternLocale = "und_" + rg.prefix(2).uppercased()
        }
        return ICUPatternGenerator.cachedPatternGenerator(localeIdentifier: patternLocale, calendarIdentifier: calendar.identifier)?.defaultHourCycle ?? .zeroToTwentyThree
    }

    fileprivate static func keywordValue(_ identifier: String, _ key: String) -> String? {
        _withFixedCharBuffer { buffer, size, status in
            uloc_getKeywordValue(identifier, key, buffer, size, &status)
        }
    }
}

extension Calendar {
    // Calendar_ICU.swift builds this through Locale.Components; uloc_setKeywordValue gives the same.
    static func localeIdentifierWithCalendar(localeIdentifier: String, calendarIdentifier: Calendar.Identifier) -> String? {
        let cldr = calendarIdentifier.cldrIdentifier
        let capacity = Int(ULOC_FULLNAME_CAPACITY + ULOC_KEYWORD_AND_VALUES_CAPACITY)
        var buffer = [CChar](repeating: 0, count: capacity)
        var status = U_ZERO_ERROR
        // Canonicalizing first folds a BCP 47 `-u-ca-` extension into the keyword being replaced.
        let canonicalLength = uloc_canonicalize(localeIdentifier, &buffer, Int32(capacity), &status)
        guard status.isSuccess, canonicalLength < capacity else { return nil }
        let len = uloc_setKeywordValue("calendar", cldr, &buffer, Int32(capacity), &status)
        guard status.isSuccess, len > 0 else { return nil }
        return String(cString: buffer)
    }
}

extension Calendar.Identifier {
    // From FoundationEssentials/Calendar/Calendar.swift.
    var cldrIdentifier: String {
        switch self {
        case .gregorian: return "gregorian"
        case .buddhist: return "buddhist"
        case .chinese: return "chinese"
        case .coptic: return "coptic"
        case .ethiopicAmeteMihret: return "ethiopic"
        case .ethiopicAmeteAlem: return "ethioaa"
        case .hebrew: return "hebrew"
        case .iso8601: return "iso8601"
        case .indian: return "indian"
        case .islamic: return "islamic"
        case .islamicCivil: return "islamic-civil"
        case .japanese: return "japanese"
        case .persian: return "persian"
        case .republicOfChina: return "roc"
        case .islamicTabular: return "islamic-tbla"
        case .islamicUmmAlQura: return "islamic-umalqura"
        }
    }
}

extension Calendar {
    // From FoundationEssentials/Calendar/Calendar.swift, less isLeapMonth and isRepeatedDay, which
    // nothing here uses. Darling's Component has no dayOfYear, so `set` drops it, as upstream's reduce does.
    struct ComponentSet: OptionSet {
        let rawValue: UInt
        init(rawValue: UInt) { self.rawValue = rawValue }

        init(single component: Component) {
            self.rawValue = component.componentSetValue
        }

        static let era = ComponentSet(rawValue: 1 << 0)
        static let year = ComponentSet(rawValue: 1 << 1)
        static let month = ComponentSet(rawValue: 1 << 2)
        static let day = ComponentSet(rawValue: 1 << 3)
        static let hour = ComponentSet(rawValue: 1 << 4)
        static let minute = ComponentSet(rawValue: 1 << 5)
        static let second = ComponentSet(rawValue: 1 << 6)
        static let weekday = ComponentSet(rawValue: 1 << 7)
        static let weekdayOrdinal = ComponentSet(rawValue: 1 << 8)
        static let quarter = ComponentSet(rawValue: 1 << 9)
        static let weekOfMonth = ComponentSet(rawValue: 1 << 10)
        static let weekOfYear = ComponentSet(rawValue: 1 << 11)
        static let yearForWeekOfYear = ComponentSet(rawValue: 1 << 12)
        static let nanosecond = ComponentSet(rawValue: 1 << 13)
        static let calendar = ComponentSet(rawValue: 1 << 14)
        static let timeZone = ComponentSet(rawValue: 1 << 15)
        static let dayOfYear = ComponentSet(rawValue: 1 << 18)

        var set: Set<Component> {
            var result: Set<Component> = Set()
            if contains(.era) { result.insert(.era) }
            if contains(.year) { result.insert(.year) }
            if contains(.month) { result.insert(.month) }
            if contains(.day) { result.insert(.day) }
            if contains(.hour) { result.insert(.hour) }
            if contains(.minute) { result.insert(.minute) }
            if contains(.second) { result.insert(.second) }
            if contains(.weekday) { result.insert(.weekday) }
            if contains(.weekdayOrdinal) { result.insert(.weekdayOrdinal) }
            if contains(.quarter) { result.insert(.quarter) }
            if contains(.weekOfMonth) { result.insert(.weekOfMonth) }
            if contains(.weekOfYear) { result.insert(.weekOfYear) }
            if contains(.yearForWeekOfYear) { result.insert(.yearForWeekOfYear) }
            if contains(.nanosecond) { result.insert(.nanosecond) }
            if contains(.calendar) { result.insert(.calendar) }
            if contains(.timeZone) { result.insert(.timeZone) }
            return result
        }
    }
}

extension Calendar.Component {
    fileprivate var componentSetValue: Calendar.ComponentSet.RawValue {
        switch self {
        case .era: return Calendar.ComponentSet.era.rawValue
        case .year: return Calendar.ComponentSet.year.rawValue
        case .month: return Calendar.ComponentSet.month.rawValue
        case .day: return Calendar.ComponentSet.day.rawValue
        case .hour: return Calendar.ComponentSet.hour.rawValue
        case .minute: return Calendar.ComponentSet.minute.rawValue
        case .second: return Calendar.ComponentSet.second.rawValue
        case .weekday: return Calendar.ComponentSet.weekday.rawValue
        case .weekdayOrdinal: return Calendar.ComponentSet.weekdayOrdinal.rawValue
        case .quarter: return Calendar.ComponentSet.quarter.rawValue
        case .weekOfMonth: return Calendar.ComponentSet.weekOfMonth.rawValue
        case .weekOfYear: return Calendar.ComponentSet.weekOfYear.rawValue
        case .yearForWeekOfYear: return Calendar.ComponentSet.yearForWeekOfYear.rawValue
        case .nanosecond: return Calendar.ComponentSet.nanosecond.rawValue
        case .calendar: return Calendar.ComponentSet.calendar.rawValue
        case .timeZone: return Calendar.ComponentSet.timeZone.rawValue
        }
    }

    // From FoundationEssentials/Calendar/Calendar_Enumerate.swift.
    var nextHigherUnit: Self? {
        switch self {
        case .timeZone, .calendar:
            return nil
        case .era:
            return nil
        case .year, .yearForWeekOfYear:
            return .era
        case .weekOfYear:
            return .yearForWeekOfYear
        case .quarter, .month:
            return .year
        case .day, .weekOfMonth, .weekdayOrdinal:
            return .month
        case .weekday:
            return .weekOfMonth
        case .hour:
            return .day
        case .minute:
            return .hour
        case .second:
            return .minute
        case .nanosecond:
            return .second
        }
    }

    // From Calendar_ICU.swift, less the cases Darling's Component lacks.
    init?(_ icuFieldCode: UCalendarDateFields) {
        switch icuFieldCode {
        case UCAL_ERA:
            self = .era
        case UCAL_YEAR, UCAL_EXTENDED_YEAR:
            self = .year
        case UCAL_MONTH:
            self = .month
        case UCAL_WEEK_OF_YEAR:
            self = .weekOfYear
        case UCAL_WEEK_OF_MONTH:
            self = .weekOfMonth
        case UCAL_DATE, UCAL_DAY_OF_MONTH:
            self = .day
        case UCAL_DAY_OF_WEEK:
            self = .weekday
        case UCAL_DAY_OF_WEEK_IN_MONTH:
            self = .weekdayOrdinal
        case UCAL_HOUR, UCAL_HOUR_OF_DAY:
            self = .hour
        case UCAL_MINUTE:
            self = .minute
        case UCAL_SECOND:
            self = .second
        case UCAL_ZONE_OFFSET:
            self = .timeZone
        case UCAL_YEAR_WOY:
            self = .yearForWeekOfYear
        default:
            return nil
        }
    }
}

// ICU+Foundation.swift logs through Logger.error, which Darling's os overlay lacks.
extension Logger {
    func error(_ message: String) {
        os_log(.error, log: logObject, "%{public}@", message as NSString)
    }
}

// From FoundationEssentials/String/String+Internals.swift.
extension String {
    func _trimmingWhitespace() -> String {
        if self.isEmpty {
            return ""
        }

        return String(unicodeScalars._trimmingCharacters {
            $0.properties.isWhitespace
        })
    }

    init?(_utf16 input: UnsafeBufferPointer<UInt16>) {
        // Allocate input.count * 3 code points since one UTF16 code point may require up to three UTF8 code points when transcoded
        let str = withUnsafeTemporaryAllocation(of: UTF8.CodeUnit.self, capacity: input.count * 3) { contents in
            var count = 0
            let error = transcode(input.makeIterator(), from: UTF16.self, to: UTF8.self, stoppingOnError: true) { codeUnit in
                contents[count] = codeUnit
                count += 1
            }

            guard !error else {
                return nil as String?
            }

            return String._tryFromUTF8(UnsafeBufferPointer(rebasing: contents[..<count]))
        }

        guard let str else {
            return nil
        }
        self = str
    }

    init?(_utf16 input: UnsafeMutableBufferPointer<UInt16>, count: Int) {
        guard let str = String(_utf16: UnsafeBufferPointer(rebasing: input[..<count])) else {
            return nil
        }
        self = str
    }

    init?(_utf16 input: UnsafePointer<UInt16>, count: Int) {
        guard let str = String(_utf16: UnsafeBufferPointer(start: input, count: count)) else {
            return nil
        }
        self = str
    }
}

// From Date+FormatStyle.swift, whose non-framework branch names the FoundationEssentials module.
@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension Date {
    public func formatted<F: Foundation.FormatStyle>(_ format: F) -> F.FormatOutput where F.FormatInput == Date {
        format.format(self)
    }

    public init<T: Foundation.ParseStrategy>(_ value: T.ParseInput, strategy: T) throws where T.ParseOutput == Self {
        self = try strategy.parse(value)
    }

    @_disfavoredOverload
    public init<T: Foundation.ParseStrategy, Value: StringProtocol>(_ value: Value, strategy: T) throws where T.ParseOutput == Self, T.ParseInput == String {
        self = try strategy.parse(String(value))
    }
}
