//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// Darling: swift-foundation ships only Field off-Darwin (Date+ComponentsFormatStyle+Stub.swift,
// kept verbatim below). The rest follows the macOS SDK interface and its documentation.

internal import _FoundationICU

extension Date {

    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public struct ComponentsFormatStyle : Foundation.FormatStyle, Codable, Hashable, Sendable {
        public struct Field : Codable, Hashable, Sendable {
            enum Option : Int, Codable, Hashable, CaseIterable, Comparable {
                case year
                case month
                case week
                case day
                case hour
                case minute
                case second

                var component: Calendar.Component {
                    switch self {
                    case .year:
                        return .year
                    case .month:
                        return .month
                    case .week:
                        return .weekOfMonth
                    case .day:
                        return .day
                    case .hour:
                        return .hour
                    case .minute:
                        return .minute
                    case .second:
                        return .second
                    }
                }

                init?(component: Calendar.Component) {
                    switch component {
                    case .year:
                        self = .year
                    case .month:
                        self = .month
                    case .weekOfYear, .weekOfMonth:
                        self = .week
                    case .day:
                        self = .day
                    case .hour:
                        self = .hour
                    case .minute:
                        self = .minute
                    case .second:
                        self = .second
                    default:
                        return nil
                    }
                }

                static func <(lhs: Self, rhs: Self) -> Bool {
                    lhs.rawValue > rhs.rawValue
                }
            }

            var option: Option
            public static var year: Field { .init(option: .year) }
            public static var month: Field { .init(option: .month) }
            public static var week: Field { .init(option: .week) }
            public static var day: Field { .init(option: .day) }
            public static var hour: Field { .init(option: .hour) }
            public static var minute: Field { .init(option: .minute) }
            public static var second: Field { .init(option: .second) }
        }

        public struct Style : Codable, Hashable, Sendable {
            enum Option : Int, Codable, Hashable {
                case wide
                case abbreviated
                case condensedAbbreviated
                case narrow
                case spellOut
                // Positional ("1:05:03"), reachable only through `timeDuration`.
                case positional
            }

            var option: Option

            /// Shows the fields in their full spelling, e.g. "2 hours, 10 minutes".
            public static var wide: Style { .init(option: .wide) }
            /// Shows the fields in the abbreviation, e.g. "2 hr, 10 min".
            public static var abbreviated: Style { .init(option: .abbreviated) }
            /// Uses the abbreviated form but condensed if possible, e.g. "2hr 10min".
            public static var condensedAbbreviated: Style { .init(option: .condensedAbbreviated) }
            /// Shows the fields in the shortest form possible, e.g. "2h 10m".
            public static var narrow: Style { .init(option: .narrow) }
            /// Spells out values and shows fields in their full name, e.g. "two hours, ten minutes".
            public static var spellOut: Style { .init(option: .spellOut) }
        }

        public var style: Style
        public var fields: Set<Field>?
        public var calendar: Calendar
        public var locale: Locale

        /// Whether the range reads from `lowerBound` to `upperBound` (`true`) or the reverse.
        @available(macOS 15, iOS 18, tvOS 18, watchOS 11, *)
        public var isPositive: Bool {
            get { _isPositive }
            set { _isPositive = newValue }
        }

        var _isPositive: Bool = true

        public init(style: Style, locale: Locale = .autoupdatingCurrent, calendar: Calendar = .autoupdatingCurrent, fields: Set<Field>? = nil) {
            self.style = style
            self.locale = locale
            self.calendar = calendar
            self.fields = fields
        }

        public func calendar(_ calendar: Calendar) -> Self {
            var new = self
            new.calendar = calendar
            return new
        }

        public func locale(_ locale: Locale) -> Self {
            var new = self
            new.locale = locale
            return new
        }

        public func format(_ v: Range<Date>) -> String {
            let measures = displayedMeasures(of: currentComponents(v))
            guard !measures.isEmpty else { return "" }
            return ICUMeasureFormatter.cached(locale: locale, style: style.option)?.format(measures) ?? ""
        }

        private enum CodingKeys: String, CodingKey {
            case style, fields, calendar, locale, isPositive
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            style = try container.decode(Style.self, forKey: .style)
            fields = try container.decodeIfPresent(Set<Field>.self, forKey: .fields)
            calendar = try container.decode(Calendar.self, forKey: .calendar)
            locale = try container.decode(Locale.self, forKey: .locale)
            _isPositive = try container.decodeIfPresent(Bool.self, forKey: .isPositive) ?? true
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(style, forKey: .style)
            try container.encodeIfPresent(fields, forKey: .fields)
            try container.encode(calendar, forKey: .calendar)
            try container.encode(locale, forKey: .locale)
            try container.encode(_isPositive, forKey: .isPositive)
        }

        // MARK: Components

        /// Fields in descending order; all of them when `fields` is nil.
        private var orderedFields: [Field.Option] {
            (fields.map { $0.map(\.option) } ?? Field.Option.allCases).sorted(by: >)
        }

        /// The value of each field, from the fixed end of `range` to its moving end.
        private func currentComponents(_ range: Range<Date>) -> [(Field.Option, Int)] {
            let options = orderedFields
            let (from, to) = _isPositive ? (range.lowerBound, range.upperBound) : (range.upperBound, range.lowerBound)
            let dc = calendar.dateComponents(Set(options.map(\.component)), from: from, to: to)
            return options.map { ($0, dc.value(for: $0.component) ?? 0) }
        }

        private func displayedMeasures(of values: [(Field.Option, Int)]) -> [(Field.Option, Int)] {
            if style.option == .positional {
                // Leading zero fields are dropped; a positional value keeps at least two.
                let first = values.firstIndex { $0.1 != 0 } ?? values.count
                return Array(values[min(first, max(values.count - 2, 0))...])
            }
            let nonZero = values.filter { $0.1 != 0 }
            if nonZero.isEmpty, let smallest = values.last {
                return [smallest]
            }
            return nonZero
        }
    }
}

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
extension FormatStyle where Self == Date.ComponentsFormatStyle {
    public static func components(style: Date.ComponentsFormatStyle.Style, fields: Set<Date.ComponentsFormatStyle.Field>? = nil) -> Self {
        .init(style: style, fields: fields)
    }

    /// Positional hours, minutes and seconds, e.g. "1:05:03".
    public static var timeDuration: Date.ComponentsFormatStyle {
        .init(style: .init(option: .positional), fields: [.hour, .minute, .second])
    }
}

// MARK: DiscreteFormatStyle Conformance

@available(macOS 15, iOS 18, tvOS 18, watchOS 11, *)
extension Date.ComponentsFormatStyle : DiscreteFormatStyle {
    // CFCalendar floors both dates to whole milliseconds, so no finer boundary is observable.
    private static let calendarResolution: TimeInterval = 0.001
    // Month and year clamping can absorb at most a couple of whole-unit steps.
    private static let maximumSteps = 4

    private func moving(_ input: Range<Date>, to date: Date) -> Range<Date> {
        _isPositive ? input.lowerBound..<date : date..<input.upperBound
    }

    /// Where the shown components first change as the moving end steps in `direction`: step whole
    /// smallest-field units until they differ (clamping can absorb a step), then bisect.
    private func nextChange(_ input: Range<Date>, forward: Bool) -> Date? {
        guard let smallest = orderedFields.last else { return nil }
        let current = currentComponents(input).map(\.1)
        let start = _isPositive ? input.upperBound : input.lowerBound
        var near = start
        var far = start
        for step in 1...Self.maximumSteps {
            guard var candidate = calendar.date(byAdding: smallest.component, value: forward ? step : -step, to: start) else { return nil }
            if _isPositive && candidate < input.lowerBound { candidate = input.lowerBound }
            if !_isPositive && candidate > input.upperBound { candidate = input.upperBound }
            guard candidate != far else { return nil }
            far = candidate
            if currentComponents(moving(input, to: far)).map(\.1) != current { break }
            near = far
            if step == Self.maximumSteps { return far }
        }
        while abs(far.timeIntervalSince(near)) > Self.calendarResolution {
            let mid = near + far.timeIntervalSince(near) / 2
            if currentComponents(moving(input, to: mid)).map(\.1) == current {
                near = mid
            } else {
                far = mid
            }
        }
        return far
    }

    public func discreteInput(before input: Range<Date>) -> Range<Date>? {
        nextChange(input, forward: false).map { moving(input, to: $0) }
    }

    public func discreteInput(after input: Range<Date>) -> Range<Date>? {
        nextChange(input, forward: true).map { moving(input, to: $0) }
    }

    public func input(before input: Range<Date>) -> Range<Date>? {
        if _isPositive {
            let upper = Calendar.nextAccuracyStep(for: input.upperBound, direction: .backward)
            return upper < input.upperBound && upper >= input.lowerBound ? input.lowerBound..<upper : nil
        }
        let lower = Calendar.nextAccuracyStep(for: input.lowerBound, direction: .backward)
        return lower < input.lowerBound ? lower..<input.upperBound : nil
    }

    public func input(after input: Range<Date>) -> Range<Date>? {
        if _isPositive {
            let upper = Calendar.nextAccuracyStep(for: input.upperBound, direction: .forward)
            return upper > input.upperBound ? input.lowerBound..<upper : nil
        }
        let lower = Calendar.nextAccuracyStep(for: input.lowerBound, direction: .forward)
        return lower > input.lowerBound && lower <= input.upperBound ? lower..<input.upperBound : nil
    }
}

// MARK: ICU

/// Apple ICU's measure formatter (`uameasureformat.h`), which is what gives each style its unit
/// names and list conventions.
final class ICUMeasureFormatter : @unchecked Sendable {
    private let measfmt: OpaquePointer
    private let spellOut: Bool
    private let localeIdentifier: String

    private init?(localeIdentifier: String, style: Date.ComponentsFormatStyle.Style.Option) {
        var status = U_ZERO_ERROR
        let width: UAMeasureFormatWidth
        var numberFormat: UnsafeMutablePointer<UNumberFormat?>? = nil
        switch style {
        case .wide: width = UAMEASFMT_WIDTH_WIDE
        case .abbreviated: width = UAMEASFMT_WIDTH_SHORT
        case .condensedAbbreviated: width = UAMEASFMT_WIDTH_SHORTER
        case .narrow: width = UAMEASFMT_WIDTH_NARROW
        case .positional: width = UAMEASFMT_WIDTH_NUMERIC
        case .spellOut:
            width = UAMEASFMT_WIDTH_WIDE
            numberFormat = unum_open(UNUM_SPELLOUT, nil, 0, localeIdentifier, nil, &status)
            guard status.checkSuccessAndLogError("unum_open(UNUM_SPELLOUT) failed.") else { return nil }
        }
        guard let fmt = uameasfmt_open(localeIdentifier, width, numberFormat, &status),
              status.checkSuccessAndLogError("uameasfmt_open failed.") else {
            return nil
        }
        measfmt = fmt
        spellOut = style == .spellOut
        self.localeIdentifier = localeIdentifier
    }

    deinit {
        uameasfmt_close(measfmt)
    }

    func format(_ measures: [(Date.ComponentsFormatStyle.Field.Option, Int)]) -> String? {
        let icuMeasures = measures.map { UAMeasure(value: Double($0.1), unit: $0.0.icuUnit) }
        guard spellOut else {
            return _withResizingUCharBuffer { buffer, size, status in
                uameasfmt_formatMultiple(measfmt, icuMeasures, Int32(icuMeasures.count), buffer, size, &status)
            }
        }
        // formatMultiple applies the spell-out formatter to the last value only, so each
        // measure is formatted alone and joined with the locale's unit list pattern.
        var parts: [String] = []
        for measure in icuMeasures {
            let part = _withResizingUCharBuffer { buffer, size, status in
                uameasfmt_format(measfmt, measure.value, measure.unit, buffer, size, &status)
            }
            guard let part else { return nil }
            parts.append(part)
        }
        return ICUMeasureFormatter.joinUnits(parts, localeIdentifier: localeIdentifier)
    }

    private static func joinUnits(_ parts: [String], localeIdentifier: String) -> String? {
        var status = U_ZERO_ERROR
        guard let list = ulistfmt_openForType(localeIdentifier, ULISTFMT_TYPE_UNITS, ULISTFMT_WIDTH_WIDE, &status),
              status.checkSuccessAndLogError("ulistfmt_openForType failed.") else {
            return nil
        }
        defer { ulistfmt_close(list) }
        let lengths = parts.map { Int32($0.utf16.count) }
        let joined = Array(parts.joined().utf16)
        return joined.withUnsafeBufferPointer { chars -> String? in
            guard let base = chars.baseAddress else { return nil }
            var offset = 0
            let pointers: [UnsafePointer<UChar>?] = lengths.map { length in
                defer { offset += Int(length) }
                return base + offset
            }
            return _withResizingUCharBuffer { buffer, size, status in
                ulistfmt_format(list, pointers, lengths, Int32(parts.count), buffer, size, &status)
            }
        }
    }

    private struct CacheKey : Hashable, Sendable {
        var localeIdentifier: String
        var style: Date.ComponentsFormatStyle.Style.Option
    }

    private static let cache = FormatterCache<CacheKey, ICUMeasureFormatter?>()

    static func cached(locale: Locale, style: Date.ComponentsFormatStyle.Style.Option) -> ICUMeasureFormatter? {
        cache.formatter(for: CacheKey(localeIdentifier: locale.identifier, style: style)) {
            ICUMeasureFormatter(localeIdentifier: locale.identifier, style: style)
        }
    }
}

extension Date.ComponentsFormatStyle.Field.Option {
    fileprivate var icuUnit: UAMeasureUnit {
        switch self {
        case .year: return UAMEASUNIT_DURATION_YEAR
        case .month: return UAMEASUNIT_DURATION_MONTH
        case .week: return UAMEASUNIT_DURATION_WEEK
        case .day: return UAMEASUNIT_DURATION_DAY
        case .hour: return UAMEASUNIT_DURATION_HOUR
        case .minute: return UAMEASUNIT_DURATION_MINUTE
        case .second: return UAMEASUNIT_DURATION_SECOND
        }
    }
}
