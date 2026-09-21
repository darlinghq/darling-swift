//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// Calendar, from release/5.4 stdlib/public/Darwin/Foundation/Calendar.swift.
// Darling's NSCalendar only has the identifier, locale, time zone, week settings, unit ranges, ordinality,
// -rangeOfUnit:startDate:interval:forDate:, -dateFromComponents:, -components:fromDate:(toDate:) and
// -dateByAddingComponents:, so:
// - startOfDay, the granularity comparisons, isDateInToday/Yesterday/Tomorrow/Weekend, date(bySetting...),
//   nextDate, enumerateDates and date(_:matchesComponents:) are written in Swift on top of those. The date search
//   steps through candidate dates (jumping over mismatching larger units); it does not adjust to the nearest existing
//   time for a nonexistent one, and RepeatedTimePolicy.last is treated like .first.
// - Weekends are Saturday and Sunday, since Darling has no locale weekend data, and the weekend interval searches
//   (dateIntervalOfWeekend, nextWeekend) are left out. The symbol lists come from NSDateFormatter.
// - Quarters are derived from months (Darling computes fiscal quarters and can't add or range them). Unit ranges it
//   doesn't support (reported as kCFNotFound) are nil, or computed in Swift for weekOfMonth-in-month and
//   weekday-in-week.
// - Darling's CoreFoundation can only create some calendars, so current/autoupdatingCurrent fall back to Gregorian.
// - Its range, ordinality and time-range functions crash on units without an ICU field (quarter, nanosecond,
//   calendar, timeZone), so those are answered in Swift before reaching it.
// - -copyWithZone: loses the time zone, locale and week settings, and NSAutoCalendar has none, so copies are made by
//   hand and autoupdating calendars are adopted.
// - NSCalendarIdentifier* strings aren't the identifiers Darling's CoreFoundation accepts (kCFGregorianCalendar...).

@_exported import Foundation // Clang module
import ObjectiveC

/// Holds the calendar reference; `Calendar` copies it on write.
private final class _CalendarBox {
    let reference: NSCalendar
    init(_ reference: NSCalendar) { self.reference = reference }
}

/**
 `Calendar` encapsulates information about systems of reckoning time in which the beginning, length, and divisions of a year are defined. It provides information about the calendar and support for calendrical computations such as determining the range of a given calendrical unit and adding units to a given absolute time.
*/
public struct Calendar : Hashable, Equatable, ReferenceConvertible {
    public typealias ReferenceType = NSCalendar

    private var _autoupdating: Bool
    private var _box: _CalendarBox

    /// Calendar supports many different kinds of calendars. Each is identified by an identifier here.
    public enum Identifier {
        /// The common calendar in Europe, the Western Hemisphere, and elsewhere.
        case gregorian

        case buddhist
        case chinese
        case coptic
        case ethiopicAmeteMihret
        case ethiopicAmeteAlem
        case hebrew
        case iso8601
        case indian
        case islamic
        case islamicCivil
        case japanese
        case persian
        case republicOfChina

        /// A simple tabular Islamic calendar using the astronomical/Thursday epoch of CE 622 July 15
        @available(macOS 10.10, iOS 8.0, *)
        case islamicTabular

        /// The Islamic Umm al-Qura calendar used in Saudi Arabia. This is based on astronomical calculation, instead of tabular behavior.
        @available(macOS 10.10, iOS 8.0, *)
        case islamicUmmAlQura
    }

    /// An enumeration for the various components of a calendar date.
    ///
    /// Several `Calendar` APIs use either a single unit or a set of units as input to a search algorithm.
    ///
    /// - seealso: `DateComponents`
    public enum Component {
        case era
        case year
        case month
        case day
        case hour
        case minute
        case second
        case weekday
        case weekdayOrdinal
        case quarter
        case weekOfMonth
        case weekOfYear
        case yearForWeekOfYear
        case nanosecond
        case calendar
        case timeZone
    }

    /// Returns the user's current calendar.
    ///
    /// This calendar does not track changes that the user makes to their preferences.
    public static var current : Calendar {
        // Darling's CoreFoundation can't create every locale's calendar (+currentCalendar is then nil).
        let reference = (NSCalendar.currentCalendar() as? NSCalendar) ?? Calendar._makeReference(.gregorian)
        return Calendar(adoptingReference: reference, autoupdating: false)
    }

    /// A Calendar that tracks changes to user's preferred calendar.
    ///
    /// If mutated, this calendar will no longer track the user's preferred calendar.
    ///
    /// - note: The autoupdating Calendar will only compare equal to another autoupdating Calendar.
    public static var autoupdatingCurrent : Calendar {
        if let reference = NSCalendar.autoupdatingCurrentCalendar() as? NSCalendar, reference.calendarIdentifier() != nil {
            return Calendar(adoptingReference: reference, autoupdating: true)
        }
        // NSAutoCalendar wraps a nil calendar when +currentCalendar is nil.
        return Calendar(adoptingReference: Calendar._makeReference(.gregorian), autoupdating: true)
    }

    // MARK: -
    // MARK: init

    /// Returns a new Calendar.
    ///
    /// - parameter identifier: The kind of calendar to use.
    public init(identifier: __shared Identifier) {
        _box = _CalendarBox(Calendar._makeReference(identifier))
        _autoupdating = false
    }

    // MARK: -
    // MARK: Bridging

    fileprivate init(reference : __shared NSCalendar) {
        _autoupdating = Calendar._isAutoupdating(reference)
        _box = _CalendarBox(_autoupdating ? reference : Calendar._copy(reference))
    }

    private init(adoptingReference reference: NSCalendar, autoupdating: Bool) {
        _box = _CalendarBox(reference)
        _autoupdating = autoupdating
    }

    private var _ns: NSCalendar {
        return _box.reference
    }

    private mutating func _applyMutation(_ whatToDo: (NSCalendar) -> Void) {
        if _autoupdating || !isKnownUniquelyReferenced(&_box) {
            _box = _CalendarBox(Calendar._copy(_box.reference))
            _autoupdating = false
        }
        whatToDo(_box.reference)
    }

    // MARK: -
    //

    /// The identifier of the calendar.
    public var identifier : Identifier {
        return Calendar._fromNSCalendarIdentifier(_ns.calendarIdentifier() ?? "")
    }

    /// The locale of the calendar.
    public var locale : Locale? {
        get {
            return _ns.locale().map { Locale._unconditionallyBridgeFromObjectiveC($0) }
        }
        set {
            _applyMutation { $0.setLocale(newValue?._bridgeToObjectiveC()) }
        }
    }

    /// The time zone of the calendar.
    public var timeZone : TimeZone {
        get {
            return _ns.timeZone().map { TimeZone._unconditionallyBridgeFromObjectiveC($0) } ?? TimeZone.current
        }
        set {
            _applyMutation { $0.setTimeZone(newValue._bridgeToObjectiveC()) }
        }
    }

    /// The first weekday of the calendar.
    public var firstWeekday : Int {
        get {
            return _ns.firstWeekday()
        }
        set {
            _applyMutation { $0.setFirstWeekday(newValue) }
        }
    }

    /// The number of minimum days in the first week.
    public var minimumDaysInFirstWeek : Int {
        get {
            return _ns.minimumDaysInFirstWeek()
        }
        set {
            _applyMutation { $0.setMinimumDaysInFirstWeek(newValue) }
        }
    }

    // MARK: - Symbols (from a date formatter using this calendar and its locale)

    private func _formatter() -> NSDateFormatter? {
        guard let formatter = NSDateFormatter() as NSDateFormatter? else { return nil }
        // NSDateFormatter declares calendar, timeZone and locale as @property, so these are
        // assignments rather than setX(_:) calls. _ns.locale() stays a method call because
        // NSCalendar's accessors are still method pairs; if those are ever converted too, the
        // getter here has to become _ns.locale as well, since a Swift property cannot be called.
        formatter.calendar = _ns
        if let locale = _ns.locale() {
            formatter.locale = locale
        }
        return formatter
    }

    private func _symbols(_ symbols: (NSDateFormatter) -> [Any]?) -> [String] {
        guard let formatter = _formatter() else { return [] }
        return (symbols(formatter) ?? []).compactMap { $0 as? String }
    }

    private func _symbol(_ symbol: (NSDateFormatter) -> String?) -> String {
        guard let formatter = _formatter() else { return "" }
        return symbol(formatter) ?? ""
    }

    /// A list of eras in this calendar, localized to the Calendar's `locale`.
    public var eraSymbols: [String] { return _symbols { $0.eraSymbols() } }

    /// A list of longer-named eras in this calendar, localized to the Calendar's `locale`.
    public var longEraSymbols: [String] { return _symbols { $0.longEraSymbols() } }

    /// A list of months in this calendar, localized to the Calendar's `locale`.
    public var monthSymbols: [String] { return _symbols { $0.monthSymbols() } }

    /// A list of shorter-named months in this calendar, localized to the Calendar's `locale`.
    public var shortMonthSymbols: [String] { return _symbols { $0.shortMonthSymbols() } }

    /// A list of very-shortly-named months in this calendar, localized to the Calendar's `locale`.
    public var veryShortMonthSymbols: [String] { return _symbols { $0.veryShortMonthSymbols() } }

    /// A list of standalone months in this calendar, localized to the Calendar's `locale`.
    public var standaloneMonthSymbols: [String] { return _symbols { $0.standaloneMonthSymbols() } }

    /// A list of shorter-named standalone months in this calendar, localized to the Calendar's `locale`.
    public var shortStandaloneMonthSymbols: [String] { return _symbols { $0.shortStandaloneMonthSymbols() } }

    /// A list of very-shortly-named standalone months in this calendar, localized to the Calendar's `locale`.
    public var veryShortStandaloneMonthSymbols: [String] { return _symbols { $0.veryShortStandaloneMonthSymbols() } }

    /// A list of weekdays in this calendar, localized to the Calendar's `locale`.
    public var weekdaySymbols: [String] { return _symbols { $0.weekdaySymbols() } }

    /// A list of shorter-named weekdays in this calendar, localized to the Calendar's `locale`.
    public var shortWeekdaySymbols: [String] { return _symbols { $0.shortWeekdaySymbols() } }

    /// A list of very-shortly-named weekdays in this calendar, localized to the Calendar's `locale`.
    public var veryShortWeekdaySymbols: [String] { return _symbols { $0.veryShortWeekdaySymbols() } }

    /// A list of standalone weekday names in this calendar, localized to the Calendar's `locale`.
    public var standaloneWeekdaySymbols: [String] { return _symbols { $0.standaloneWeekdaySymbols() } }

    /// A list of shorter-named standalone weekdays in this calendar, localized to the Calendar's `locale`.
    public var shortStandaloneWeekdaySymbols: [String] { return _symbols { $0.shortStandaloneWeekdaySymbols() } }

    /// A list of very-shortly-named weekdays in this calendar, localized to the Calendar's `locale`.
    public var veryShortStandaloneWeekdaySymbols: [String] { return _symbols { $0.veryShortStandaloneWeekdaySymbols() } }

    /// A list of quarter names in this calendar, localized to the Calendar's `locale`.
    public var quarterSymbols: [String] { return _symbols { $0.quarterSymbols() } }

    /// A list of shorter-named quarters in this calendar, localized to the Calendar's `locale`.
    public var shortQuarterSymbols: [String] { return _symbols { $0.shortQuarterSymbols() } }

    /// A list of standalone quarter names in this calendar, localized to the Calendar's `locale`.
    public var standaloneQuarterSymbols: [String] { return _symbols { $0.standaloneQuarterSymbols() } }

    /// A list of shorter-named standalone quarters in this calendar, localized to the Calendar's `locale`.
    public var shortStandaloneQuarterSymbols: [String] { return _symbols { $0.shortStandaloneQuarterSymbols() } }

    /// The symbol used to represent "AM", localized to the Calendar's `locale`.
    public var amSymbol: String { return _symbol { $0.amSymbol() } }

    /// The symbol used to represent "PM", localized to the Calendar's `locale`.
    public var pmSymbol: String { return _symbol { $0.pmSymbol() } }

    // MARK: -
    //

    /// Returns the minimum range limits of the values that a given component can take on in the receiver.
    ///
    /// As an example, in the Gregorian calendar the minimum range of values for the Day component is 1-28.
    /// - parameter component: A component to calculate a range for.
    /// - returns: The range, or nil if it could not be calculated.
    public func minimumRange(of component: Component) -> Range<Int>? {
        if let range = Calendar._rangeWithoutICUField(component) { return range }
        if Calendar._unitsWithoutICUField.contains(component) { return nil }
        return Calendar._range(_ns.minimumRange(of: Calendar._toCalendarUnit([component])))
    }

    /// The maximum range limits of the values that a given component can take on in the receive
    ///
    /// As an example, in the Gregorian calendar the maximum range of values for the Day component is 1-31.
    /// - parameter component: A component to calculate a range for.
    /// - returns: The range, or nil if it could not be calculated.
    public func maximumRange(of component: Component) -> Range<Int>? {
        if let range = Calendar._rangeWithoutICUField(component) { return range }
        if Calendar._unitsWithoutICUField.contains(component) { return nil }
        return Calendar._range(_ns.maximumRange(of: Calendar._toCalendarUnit([component])))
    }

    /// Units Darling's CoreFoundation has no ICU field for: passing them to its range and ordinality functions crashes.
    private static let _unitsWithoutICUField: Set<Component> = [.quarter, .nanosecond, .calendar, .timeZone]

    /// The minimum and maximum ranges of the units without an ICU field, where they have one.
    private static func _rangeWithoutICUField(_ component: Component) -> Range<Int>? {
        switch component {
        case .quarter: return 1..<5
        case .nanosecond: return 0..<1_000_000_000
        default: return nil
        }
    }

    /// Darling's CoreFoundation reports unsupported unit combinations as {kCFNotFound, kCFNotFound}.
    private static func _range(_ range: NSRange) -> Range<Int>? {
        guard range.location != NSNotFound, range.location >= 0, range.length >= 0 else { return nil }
        return range.location..<(range.location + range.length)
    }

    /// Returns the range of absolute time values that a smaller calendar component (such as a day) can take on in a larger calendar component (such as a month) that includes a specified absolute time.
    ///
    /// You can use this method to calculate, for example, the range the `day` component can take on in the `month` in which `date` lies.
    /// - parameter smaller: The smaller calendar component.
    /// - parameter larger: The larger calendar component.
    /// - parameter date: The absolute time for which the calculation is performed.
    /// - returns: The range of absolute time values smaller can take on in larger at the time specified by date. Returns `nil` if larger is not logically bigger than smaller in the calendar, or the given combination of components does not make sense (or is a computation which is undefined).
    public func range(of smaller: Component, in larger: Component, for date: Date) -> Range<Int>? {
        // Darling's CoreFoundation has no ICU field for these units and crashes on them.
        if Calendar._unitsWithoutICUField.contains(smaller) || Calendar._unitsWithoutICUField.contains(larger) {
            switch (smaller, larger) {
            case (.quarter, .year): return 1..<5
            case (.month, .quarter):
                guard let month = dateComponents([.month], from: date).month else { return nil }
                let first = (month - 1) / 3 * 3 + 1
                return first..<(first + 3)
            default: return nil
            }
        }
        if let range = Calendar._range(_ns.range(of: Calendar._toCalendarUnit([smaller]), in: Calendar._toCalendarUnit([larger]), for: date._bridgeToObjectiveC())) {
            return range
        }
        // Darling's CoreFoundation only knows the deprecated week unit, so compute the common week-based ranges.
        switch (smaller, larger) {
        case (.weekday, .weekOfYear), (.weekday, .weekOfMonth):
            return maximumRange(of: .weekday)
        case (.weekOfMonth, .month):
            guard let month = dateInterval(of: .month, for: date),
                  let lastDay = self.date(byAdding: .day, value: -1, to: month.end) else { return nil }
            let first = component(.weekOfMonth, from: month.start)
            let last = component(.weekOfMonth, from: lastDay)
            guard first != Int.max, last != Int.max, first <= last else { return nil }
            return first..<(last + 1)
        default:
            return nil
        }
    }

    /// Returns, via two inout parameters, the starting time and duration of a given calendar component that contains a given date.
    ///
    /// - seealso: `range(of:for:)`
    /// - seealso: `dateInterval(of:for:)`
    /// - parameter component: A calendar component.
    /// - parameter start: Upon return, the starting time of the calendar component that contains the date.
    /// - parameter interval: Upon return, the duration of the calendar component that contains the date.
    /// - parameter date: The specified date.
    /// - returns: `true` if the starting time and duration of a component could be calculated, otherwise `false`.
    public func dateInterval(of component: Component, start: inout Date, interval: inout TimeInterval, for date: Date) -> Bool {
        if component == .nanosecond || component == .calendar || component == .timeZone {
            // Darling's CoreFoundation has no ICU field for these units and crashes on them.
            return false
        }
        if component == .quarter {
            // Darling has no quarter time ranges: a quarter is the three months starting at month 1, 4, 7 or 10.
            guard let month = dateInterval(of: .month, for: date),
                  let monthNumber = dateComponents([.month], from: date).month,
                  let quarterStart = self.date(byAdding: .month, value: -((monthNumber - 1) % 3), to: month.start),
                  let quarterEnd = self.date(byAdding: .month, value: 3, to: quarterStart) else { return false }
            start = quarterStart
            interval = quarterEnd.timeIntervalSince(quarterStart)
            return true
        }
        var nsDate : NSDate?
        var ti : TimeInterval = 0
        if _ns.range(of: Calendar._toCalendarUnit([component]), start: &nsDate, interval: &ti, for: date._bridgeToObjectiveC()), let startDate = nsDate {
            start = Date._unconditionallyBridgeFromObjectiveC(startDate)
            interval = ti
            return true
        } else {
            return false
        }
    }

    /// Returns the starting time and duration of a given calendar component that contains a given date.
    ///
    /// - parameter component: A calendar component.
    /// - parameter date: The specified date.
    /// - returns: A new `DateInterval` if the starting time and duration of a component could be calculated, otherwise `nil`.
    @available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
    public func dateInterval(of component: Component, for date: Date) -> DateInterval? {
        var start : Date = Date(timeIntervalSinceReferenceDate: 0)
        var interval : TimeInterval = 0
        if self.dateInterval(of: component, start: &start, interval: &interval, for: date) {
            return DateInterval(start: start, duration: interval)
        } else {
            return nil
        }
    }

    /// Returns, for a given absolute time, the ordinal number of a smaller calendar component (such as a day) within a specified larger calendar component (such as a week).
    ///
    /// - parameter smaller: The smaller calendar component.
    /// - parameter larger: The larger calendar component.
    /// - parameter date: The absolute time for which the calculation is performed.
    /// - returns: The ordinal number of smaller within larger at the time specified by date. Returns `nil` if larger is not logically bigger than smaller in the calendar, or the given combination of components does not make sense (or is a computation which is undefined).
    public func ordinality(of smaller: Component, in larger: Component, for date: Date) -> Int? {
        if Calendar._unitsWithoutICUField.contains(smaller) || Calendar._unitsWithoutICUField.contains(larger) {
            // Darling's CoreFoundation has no ICU field for these units and crashes on them.
            guard let month = dateComponents([.month], from: date).month else { return nil }
            switch (smaller, larger) {
            case (.quarter, .year): return (month - 1) / 3 + 1
            case (.month, .quarter): return (month - 1) % 3 + 1
            default: return nil
            }
        }
        let result = _ns.ordinality(of: Calendar._toCalendarUnit([smaller]), in: Calendar._toCalendarUnit([larger]), for: date._bridgeToObjectiveC())
        // Darling's CoreFoundation reports kCFNotFound (-1) rather than NSNotFound.
        if result == NSNotFound || result < 0 { return nil }
        return result
    }

    // MARK: -
    //

    /// Returns a new `Date` representing the date calculated by adding components to a given date.
    ///
    /// - parameter components: A set of values to add to the date.
    /// - parameter date: The starting date.
    /// - parameter wrappingComponents: If `true`, the component should be incremented and wrap around to zero/one on overflow, and should not cause higher components to be incremented. The default value is `false`.
    /// - returns: A new date, or nil if a date could not be calculated with the given input.
    public func date(byAdding components: DateComponents, to date: Date, wrappingComponents: Bool = false) -> Date? {
        var components = components
        if let quarter = components.quarter {
            // Darling's -dateByAddingComponents: ignores quarters.
            components.month = (components.month ?? 0) + 3 * quarter
            components.quarter = nil
        }
        let result = _ns.date(byAdding: components._bridgeToObjectiveC(), to: date._bridgeToObjectiveC(), options: wrappingComponents ? 1 /* NSCalendarWrapComponents */ : 0)
        return result.map { Date._unconditionallyBridgeFromObjectiveC($0) }
    }

    /// Returns a new `Date` representing the date calculated by adding an amount of a specific component to a given date.
    ///
    /// - parameter component: A single component to add.
    /// - parameter value: The value of the specified component to add.
    /// - parameter date: The starting date.
    /// - parameter wrappingComponents: If `true`, the component should be incremented and wrap around to zero/one on overflow, and should not cause higher components to be incremented. The default value is `false`.
    /// - returns: A new date, or nil if a date could not be calculated with the given input.
    @available(iOS 8.0, *)
    public func date(byAdding component: Component, value: Int, to date: Date, wrappingComponents: Bool = false) -> Date? {
        var components = DateComponents()
        components.setValue(value, for: component)
        return self.date(byAdding: components, to: date, wrappingComponents: wrappingComponents)
    }

    /// Returns a date created from the specified components.
    ///
    /// - parameter components: Used as input to the search algorithm for finding a corresponding date.
    /// - returns: A new `Date`, or nil if a date could not be found which matches the components.
    public func date(from components: DateComponents) -> Date? {
        // Darling's -dateFromComponents: ignores the components' time zone, so apply it to a copy of the calendar.
        var calendar = self
        if let timeZone = components.timeZone, timeZone != self.timeZone {
            calendar.timeZone = timeZone
        }
        return calendar._ns.date(from: components._bridgeToObjectiveC()).map { Date._unconditionallyBridgeFromObjectiveC($0) }
    }

    /// Returns all the date components of a date, using the calendar time zone.
    ///
    /// - note: If you want "date information in a given time zone" in order to display it, you should use `DateFormatter` to format the date.
    /// - parameter date: The `Date` to use.
    /// - returns: The date components of the specified date.
    public func dateComponents(_ components: Set<Component>, from date: Date) -> DateComponents {
        // Darling computes fiscal quarters (October to December is 0), so quarters are derived from the month.
        var units = components
        if components.contains(.quarter) {
            units.remove(.quarter)
            units.insert(.month)
        }
        let flags = Int(bitPattern: Calendar._toCalendarUnit(units).rawValue)
        var result = DateComponents._unconditionallyBridgeFromObjectiveC(_ns.components(flags, from: date._bridgeToObjectiveC()))
        if components.contains(.quarter) {
            result.quarter = result.month.map { ($0 - 1) / 3 + 1 }
            if !components.contains(.month) {
                result.month = nil
            }
        }
        return result
    }

    /// Returns all the date components of a date, as if in a given time zone (instead of the `Calendar` time zone).
    ///
    /// The time zone overrides the time zone of the `Calendar` for the purposes of this calculation.
    /// - note: If you want "date information in a given time zone" in order to display it, you should use `DateFormatter` to format the date.
    /// - parameter timeZone: The `TimeZone` to use.
    /// - parameter date: The `Date` to use.
    /// - returns: All components, calculated using the `Calendar` and `TimeZone`.
    @available(iOS 8.0, *)
    public func dateComponents(in timeZone: TimeZone, from date: Date) -> DateComponents {
        var calendar = self
        calendar.timeZone = timeZone
        return calendar.dateComponents(Set(Calendar._allComponents), from: date)
    }

    /// Returns the difference between two dates.
    ///
    /// - parameter components: Which components to compare.
    /// - parameter start: The starting date.
    /// - parameter end: The ending date.
    /// - returns: The result of calculating the difference from start to end.
    public func dateComponents(_ components: Set<Component>, from start: Date, to end: Date) -> DateComponents {
        var units = components
        if components.contains(.quarter) {
            units.remove(.quarter)
            units.insert(.month)
        }
        let flags = Int(bitPattern: Calendar._toCalendarUnit(units).rawValue)
        var result = DateComponents._unconditionallyBridgeFromObjectiveC(_ns.components(flags, from: start._bridgeToObjectiveC(), to: end._bridgeToObjectiveC(), options: 0))
        if components.contains(.quarter), let months = result.month {
            result.quarter = months / 3
            result.month = components.contains(.month) ? months % 3 : nil
        }
        return result
    }

    /// Returns the difference between two dates specified as `DateComponents`.
    ///
    /// For components which are not specified in each `DateComponents`, but required to specify an absolute date, the base value of the component is assumed.  For example, for an `DateComponents` with just a `year` and a `month` specified, a `day` of 1, and an `hour`, `minute`, `second`, and `nanosecond` of 0 are assumed.
    /// For each `DateComponents`, if its `timeZone` property is set, that time zone is used for it. If the `calendar` property is set, that is used rather than the receiving calendar, and if both the `calendar` and `timeZone` are set, the `timeZone` property value overrides the time zone of the `calendar` property.
    ///
    /// - parameter components: Which components to compare.
    /// - parameter start: The starting date components.
    /// - parameter end: The ending date components.
    /// - returns: The result of calculating the difference from start to end.
    @available(iOS 8.0, *)
    public func dateComponents(_ components: Set<Component>, from start: DateComponents, to end: DateComponents) -> DateComponents {
        guard let startDate = (start.calendar ?? self).date(from: start),
              let endDate = (end.calendar ?? self).date(from: end) else {
            return DateComponents()
        }
        return dateComponents(components, from: startDate, to: endDate)
    }

    /// Returns the value for one component of a date.
    ///
    /// - parameter component: The component to calculate.
    /// - parameter date: The date to use.
    /// - returns: The value for the component.
    @available(iOS 8.0, *)
    public func component(_ component: Component, from date: Date) -> Int {
        return dateComponents([component], from: date).value(for: component) ?? Int.max /* NSDateComponentUndefined */
    }

    /// Returns the first moment of a given Date, as a Date.
    ///
    /// For example, pass in `Date()`, if you want the start of today.
    /// If there were two midnights, it returns the first.  If there was none, it returns the first moment that did exist.
    /// - parameter date: The date to search.
    /// - returns: The first moment of the given date.
    @available(iOS 8.0, *)
    public func startOfDay(for date: Date) -> Date {
        if let interval = dateInterval(of: .day, for: date) {
            return interval.start
        }
        return self.date(from: dateComponents([.era, .year, .month, .day], from: date)) ?? date
    }

    /// Compares the given dates down to the given component, reporting them `orderedSame` if they are the same in the given component and all larger components, otherwise either `orderedAscending` or `orderedDescending`.
    ///
    /// - parameter date1: A date to compare.
    /// - parameter date2: A date to compare.
    /// - parameter: component: A granularity to compare. For example, pass `.hour` to check if two dates are in the same hour.
    @available(iOS 8.0, *)
    public func compare(_ date1: Date, to date2: Date, toGranularity component: Component) -> ComparisonResult {
        let unit: Component
        switch component {
        case .weekday, .weekdayOrdinal: unit = .day
        case .calendar, .timeZone: return .orderedSame
        default: unit = component
        }
        var first = date1
        var second = date2
        if unit != .nanosecond, let a = dateInterval(of: unit, for: date1), let b = dateInterval(of: unit, for: date2) {
            first = a.start
            second = b.start
        }
        if first < second { return .orderedAscending }
        if first > second { return .orderedDescending }
        return .orderedSame
    }

    /// Compares the given dates down to the given component, reporting them equal if they are the same in the given component and all larger components.
    ///
    /// - parameter date1: A date to compare.
    /// - parameter date2: A date to compare.
    /// - parameter component: A granularity to compare. For example, pass `.hour` to check if two dates are in the same hour.
    /// - returns: `true` if the given date is within tomorrow.
    @available(iOS 8.0, *)
    public func isDate(_ date1: Date, equalTo date2: Date, toGranularity component: Component) -> Bool {
        return compare(date1, to: date2, toGranularity: component) == .orderedSame
    }

    /// Returns `true` if the given date is within the same day as another date, as defined by the calendar and calendar's locale.
    ///
    /// - parameter date1: A date to check for containment.
    /// - parameter date2: A date to check for containment.
    /// - returns: `true` if `date1` and `date2` are in the same day.
    @available(iOS 8.0, *)
    public func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
        return isDate(date1, equalTo: date2, toGranularity: .day)
    }

    /// Returns `true` if the given date is within today, as defined by the calendar and calendar's locale.
    ///
    /// - parameter date: The specified date.
    /// - returns: `true` if the given date is within today.
    @available(iOS 8.0, *)
    public func isDateInToday(_ date: Date) -> Bool {
        return isDate(date, inSameDayAs: Date())
    }

    /// Returns `true` if the given date is within yesterday, as defined by the calendar and calendar's locale.
    ///
    /// - parameter date: The specified date.
    /// - returns: `true` if the given date is within yesterday.
    @available(iOS 8.0, *)
    public func isDateInYesterday(_ date: Date) -> Bool {
        guard let yesterday = self.date(byAdding: .day, value: -1, to: Date()) else { return false }
        return isDate(date, inSameDayAs: yesterday)
    }

    /// Returns `true` if the given date is within tomorrow, as defined by the calendar and calendar's locale.
    ///
    /// - parameter date: The specified date.
    /// - returns: `true` if the given date is within tomorrow.
    @available(iOS 8.0, *)
    public func isDateInTomorrow(_ date: Date) -> Bool {
        guard let tomorrow = self.date(byAdding: .day, value: 1, to: Date()) else { return false }
        return isDate(date, inSameDayAs: tomorrow)
    }

    /// Returns `true` if the given date is within a weekend period (Saturday or Sunday).
    ///
    /// - parameter date: The specified date.
    /// - returns: `true` if the given date is within a weekend.
    @available(iOS 8.0, *)
    public func isDateInWeekend(_ date: Date) -> Bool {
        let weekday = component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    // MARK: -
    // MARK: Searching

    /// The direction in time to search.
    public enum SearchDirection {
        /// Search for a date later in time than the start date.
        case forward

        /// Search for a date earlier in time than the start date.
        case backward
    }

    /// Determines which result to use when a time is repeated on a day in a calendar (for example, during a daylight saving transition when the times between 2:00am and 3:00am may happen twice).
    public enum RepeatedTimePolicy {
        /// If there are two or more matching times (all the components are the same, including isLeapMonth) before the end of the next instance of the next higher component to the highest specified component, then the algorithm will return the first occurrence.
        case first

        /// If there are two or more matching times (all the components are the same, including isLeapMonth) before the end of the next instance of the next higher component to the highest specified component, then the algorithm will return the last occurrence.
        case last
    }

    /// A hint to the search algorithm to control the method used for searching for dates.
    public enum MatchingPolicy {
        /// If there is no matching time before the end of the next instance of the next higher component to the highest specified component in the `DateComponents` argument, the algorithm will return the next existing time which exists.
        case nextTime

        /// If specified, and there is no matching time before the end of the next instance of the next higher component to the highest specified component in the `DateComponents` argument, the method will return the next existing value of the missing component and preserves the lower components' values (e.g., no 2:37am results in 3:37am, if that exists).
        case nextTimePreservingSmallerComponents

        /// If there is no matching time before the end of the next instance of the next higher component to the highest specified component in the `DateComponents` argument, the algorithm will return the previous existing value of the missing component and preserves the lower components' values.
        case previousTimePreservingSmallerComponents

        /// If specified, the algorithm travels as far forward or backward as necessary looking for a match.
        case strict
    }

    /// Computes the dates which match (or most closely match) a given set of components, and calls the closure once for each of them, until the enumeration is stopped.
    ///
    /// There will be at least one intervening date which does not match all the components (or the given date itself must not match) between the given date and any result.
    ///
    /// If an exact match is not possible, and requested with the `strict` option, nil is passed to the closure and the enumeration ends.
    ///
    /// The enumeration is stopped by setting `stop` to `true` in the closure and returning. It is not necessary to set `stop` to `false` to keep the enumeration going.
    /// - parameter start: The `Date` at which to start the search.
    /// - parameter components: The `DateComponents` to use as input to the search algorithm.
    /// - parameter matchingPolicy: Determines the behavior of the search algorithm when the input produces an ambiguous result.
    /// - parameter repeatedTimePolicy: Determines the behavior of the search algorithm when the input produces a time that occurs twice on a particular day.
    /// - parameter direction: Which direction in time to search. The default value is `.forward`, which means later in time.
    /// - parameter block: A closure that is called with search results.
    @available(iOS 8.0, *)
    public func enumerateDates(startingAfter start: Date, matching components: DateComponents, matchingPolicy: MatchingPolicy, repeatedTimePolicy: RepeatedTimePolicy = .first, direction: SearchDirection = .forward, using block: (_ result: Date?, _ exactMatch: Bool, _ stop: inout Bool) -> Void) {
        var searchStart = start
        var stop = false
        while !stop {
            guard let match = _nextMatch(after: searchStart, matching: components, forward: direction == .forward) else {
                if matchingPolicy == .strict {
                    block(nil, false, &stop)
                }
                return
            }
            block(match, true, &stop)
            searchStart = match
        }
    }

    /// Computes the next date which matches (or most closely matches) a given set of components.
    ///
    /// The general semantics follow those of the `enumerateDates` function.
    /// To compute a sequence of results, use the `enumerateDates` function, rather than looping and calling this method with the previous loop iteration's result.
    /// - parameter date: The starting date.
    /// - parameter components: The components to search for.
    /// - parameter matchingPolicy: Specifies the technique the search algorithm uses to find results. Default value is `.nextTime`.
    /// - parameter repeatedTimePolicy: Specifies the behavior when multiple matches are found. Default value is `.first`.
    /// - parameter direction: Specifies the direction in time to search. Default is `.forward`.
    /// - returns: A `Date` representing the result of the search, or `nil` if a result could not be found.
    @available(iOS 8.0, *)
    public func nextDate(after date: Date, matching components: DateComponents, matchingPolicy: MatchingPolicy, repeatedTimePolicy: RepeatedTimePolicy = .first, direction: SearchDirection = .forward) -> Date? {
        return _nextMatch(after: date, matching: components, forward: direction == .forward)
    }

    // MARK: -
    //

    /// Returns a new `Date` representing the date calculated by setting a specific component to a given time, and trying to keep lower components the same.  If the component already has that value, this may result in a date which is the same as the given date.
    ///
    /// Changing a component's value often will require higher or coupled components to change as well.  For example, setting the Weekday to Thursday usually will require the Day component to change its value, and possibly the Month and Year as well.
    /// If no such time exists, the next available time is returned (which could, for example, be in a different day, week, month, ... than the nominal target date).
    @available(iOS 8.0, *)
    public func date(bySetting component: Component, value: Int, of date: Date) -> Date? {
        if self.component(component, from: date) == value {
            return date
        }
        var components = DateComponents()
        components.setValue(value, for: component)
        return nextDate(after: date, matching: components, matchingPolicy: .nextTime)
    }

    /// Returns a new `Date` representing the date calculated by setting hour, minute, and second to a given time on a specified `Date`.
    ///
    /// If no such time exists, the next available time is returned (which could, for example, be in a different day than the nominal target date).
    /// The intent is to return a date on the same day as the original date argument.  This may result in a date which is backward than the given date, of course.
    /// - parameter hour: A specified hour.
    /// - parameter minute: A specified minute.
    /// - parameter second: A specified second.
    /// - parameter date: The date to start calculation with.
    /// - parameter matchingPolicy: Specifies the technique the search algorithm uses to find results. Default value is `.nextTime`.
    /// - parameter repeatedTimePolicy: Specifies the behavior when multiple matches are found. Default value is `.first`.
    /// - parameter direction: Specifies the direction in time to search. Default is `.forward`.
    /// - returns: A `Date` representing the result of the search, or `nil` if a result could not be found.
    @available(iOS 8.0, *)
    public func date(bySettingHour hour: Int, minute: Int, second: Int, of date: Date, matchingPolicy: MatchingPolicy = .nextTime, repeatedTimePolicy: RepeatedTimePolicy = .first, direction: SearchDirection = .forward) -> Date? {
        var components = dateComponents([.era, .year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = second
        return self.date(from: components)
    }

    /// Determine if the `Date` has all of the specified `DateComponents`.
    ///
    /// - returns: `true` if the date matches all of the components, otherwise `false`.
    @available(iOS 8.0, *)
    public func date(_ date: Date, matchesComponents components: DateComponents) -> Bool {
        let specified = Calendar._matchableComponents.filter { components.value(for: $0) != nil }
        let actual = dateComponents(Set(specified), from: date)
        return specified.allSatisfy { actual.value(for: $0) == components.value(for: $0) }
    }

    // MARK: - Date search

    /// The components a search can match, from the largest unit to the smallest.
    private static let _matchableComponents: [Component] = [.era, .year, .yearForWeekOfYear, .quarter, .month, .weekOfYear, .weekOfMonth, .day, .weekday, .weekdayOrdinal, .hour, .minute, .second]

    /// The unit a search steps by when `component` is the smallest one specified.
    private static func _searchUnit(_ component: Component) -> Component {
        switch component {
        case .era, .year: return .year
        case .month, .quarter: return .month
        case .yearForWeekOfYear, .weekOfYear, .weekOfMonth, .day, .weekday, .weekdayOrdinal: return .day
        default: return component
        }
    }

    /// The unit a search skips to the next instance of when `component` doesn't match.
    private static func _jumpUnit(_ component: Component) -> Component {
        switch component {
        case .yearForWeekOfYear, .quarter: return component
        default: return _searchUnit(component)
        }
    }

    private static let _searchUnitsBySize: [Component] = [.year, .month, .day, .hour, .minute, .second]

    /// Finds the first date strictly after (or before) `start` that begins a run of matching steps of the smallest
    /// specified unit, so a coarser component (a quarter, a week) or a repeated hour yields one date per instance.
    /// On a mismatch in a larger unit it skips to that unit's next (or previous) instance.
    private func _nextMatch(after start: Date, matching components: DateComponents, forward: Bool) -> Date? {
        let specified = Calendar._matchableComponents.filter { components.value(for: $0) != nil }
        guard !specified.isEmpty else { return nil }
        // Values outside the calendar's maximum range never match.
        for component in specified where component != .era && component != .year && component != .yearForWeekOfYear && component != .quarter {
            if let range = maximumRange(of: component), let value = components.value(for: component), !range.contains(value) {
                return nil
            }
        }
        if let quarter = components.quarter, !(1...4).contains(quarter) {
            return nil
        }
        // Eras only move forward in time, so an era already behind the search never comes back.
        if let wanted = components.era, let current = dateComponents([.era], from: start).era,
           forward ? wanted < current : wanted > current {
            return nil
        }
        // No later instance of the era containing `start` begins.
        if forward, specified == [.era], components.era == dateComponents([.era], from: start).era {
            return nil
        }
        // Gregorian days that don't exist in the given month (February 30) never match.
        if identifier == .gregorian || identifier == .iso8601, let day = components.day, let month = components.month,
           (1...12).contains(month), day > [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1] {
            return nil
        }
        let units = Calendar._searchUnitsBySize
        let step = specified.map(Calendar._searchUnit).max { units.firstIndex(of: $0)! < units.firstIndex(of: $1)! }!
        // Adding days keeps the time of day, which drifts after a day that has no midnight (DST starting at 00:00).
        let snapsToStep = units.firstIndex(of: step)! <= units.firstIndex(of: .day)!
        func adding(_ value: Int, to date: Date) -> Date? {
            guard let result = self.date(byAdding: step, value: value, to: date) else { return nil }
            return snapsToStep ? (dateInterval(of: step, for: result)?.start ?? result) : result
        }
        func firstMismatch(_ date: Date) -> Component? {
            let actual = dateComponents(Set(specified), from: date)
            return specified.first { actual.value(for: $0) != components.value(for: $0) }
        }
        guard var candidate = dateInterval(of: step, for: start)?.start else { return nil }
        let direction = forward ? 1 : -1
        if !forward && candidate < start {
            // The start of the step containing `start` is already before it, so it is the first backward candidate.
            guard let after = date(byAdding: step, value: 1, to: candidate) else { return nil }
            candidate = after
        }
        // Without an era, years in other calendars can repeat in another era, so only a bound stops those searches.
        let yearsMoveMonotonically = components.era != nil || identifier == .gregorian || identifier == .iso8601
        var lastYears: DateComponents?
        var yearMismatches = 0
        var budget = 50_000
        while budget > 0 {
            budget -= 1
            guard let next = adding(direction, to: candidate) else { return nil }
            candidate = next
            guard let mismatch = firstMismatch(candidate) else {
                if forward {
                    if let before = adding(-1, to: candidate), firstMismatch(before) == nil {
                        continue
                    }
                } else {
                    while budget > 0, let before = adding(-1, to: candidate), firstMismatch(before) == nil {
                        budget -= 1
                        candidate = before
                    }
                }
                return candidate
            }
            if mismatch == .era || mismatch == .year || mismatch == .yearForWeekOfYear {
                yearMismatches += 1
                let actual = dateComponents([.era, mismatch], from: candidate)
                if let value = actual.value(for: mismatch), let wanted = components.value(for: mismatch) {
                    if mismatch == .era, forward ? value > wanted : value < wanted {
                        return nil
                    }
                    // The search moved away from the wanted year within the same era.
                    if mismatch != .era, yearsMoveMonotonically, let last = lastYears, last.era == actual.era,
                       let lastValue = last.value(for: mismatch), lastValue != value,
                       (wanted - value).signum() != (value - lastValue).signum() {
                        return nil
                    }
                }
                lastYears = actual
                if yearMismatches > 1_000 {
                    return nil
                }
            }
            let unit = Calendar._jumpUnit(mismatch)
            if unit != step, let interval = dateInterval(of: unit, for: candidate) {
                // Land on the first (or last) step of the next (or previous) instance of the mismatching unit.
                if forward, let beforeEnd = date(byAdding: step, value: -1, to: interval.end) {
                    candidate = beforeEnd
                } else if !forward {
                    candidate = interval.start
                }
            }
        }
        return nil
    }

    // MARK: -

    public func hash(into hasher: inout Hasher) {
        // We need to make sure autoupdating calendars have the same hash
        if _autoupdating {
            hasher.combine(false)
        } else {
            hasher.combine(true)
            hasher.combine(identifier)
            hasher.combine(timeZone)
            hasher.combine(firstWeekday)
            hasher.combine(minimumDaysInFirstWeek)
        }
    }

    // MARK: -
    // MARK: Conversion Functions

    internal static let _allComponents: [Component] = [.era, .year, .month, .day, .hour, .minute, .second, .weekday, .weekdayOrdinal, .quarter, .weekOfMonth, .weekOfYear, .yearForWeekOfYear, .nanosecond, .calendar, .timeZone]

    /// The components a DateComponents value can set.
    internal static let _settableComponents: [Component] = [.era, .year, .month, .day, .hour, .minute, .second, .weekday, .weekdayOrdinal, .quarter, .weekOfMonth, .weekOfYear, .yearForWeekOfYear, .nanosecond]

    internal static func _toCalendarUnit(_ units : Set<Component>) -> NSCalendarUnit {
        var result: UInt = 0
        for u in units {
            switch u {
            case .era: result |= NSCalendarUnit.era.rawValue
            case .year: result |= NSCalendarUnit.year.rawValue
            case .month: result |= NSCalendarUnit.month.rawValue
            case .day: result |= NSCalendarUnit.day.rawValue
            case .hour: result |= NSCalendarUnit.hour.rawValue
            case .minute: result |= NSCalendarUnit.minute.rawValue
            case .second: result |= NSCalendarUnit.second.rawValue
            case .weekday: result |= NSCalendarUnit.weekday.rawValue
            case .weekdayOrdinal: result |= NSCalendarUnit.weekdayOrdinal.rawValue
            case .quarter: result |= NSCalendarUnit.quarter.rawValue
            case .weekOfMonth: result |= NSCalendarUnit.weekOfMonth.rawValue
            case .weekOfYear: result |= NSCalendarUnit.weekOfYear.rawValue
            case .yearForWeekOfYear: result |= NSCalendarUnit.yearForWeekOfYear.rawValue
            case .nanosecond: result |= NSCalendarUnit.nanosecond.rawValue
            case .calendar: result |= NSCalendarUnit.calendar.rawValue
            case .timeZone: result |= NSCalendarUnit.timeZone.rawValue
            }
        }
        return NSCalendarUnit(rawValue: result)
    }

    /// For each identifier: Apple's identifier string (used for coding), Darling's CoreFoundation identifier (if it has
    /// that calendar) and Darling's NSCalendarIdentifier string.
    internal static func _names(_ identifier: Identifier) -> (apple: String, coreFoundation: String?, foundation: String) {
        func cf(_ name: CFCalendarIdentifier?) -> String? { return name.map { $0.rawValue as String } }
        switch identifier {
        case .gregorian: return ("gregorian", cf(CFCalendarIdentifier.gregorianCalendar), NSCalendarIdentifierGregorian)
        case .buddhist: return ("buddhist", cf(CFCalendarIdentifier.buddhistCalendar), NSCalendarIdentifierBuddhist)
        case .chinese: return ("chinese", cf(CFCalendarIdentifier.chineseCalendar), NSCalendarIdentifierChinese)
        case .coptic: return ("coptic", nil, NSCalendarIdentifierCoptic)
        case .ethiopicAmeteMihret: return ("ethiopic", nil, NSCalendarIdentifierEthiopicAmeteMihret)
        case .ethiopicAmeteAlem: return ("ethiopic-amete-alem", nil, NSCalendarIdentifierEthiopicAmeteAlem)
        case .hebrew: return ("hebrew", cf(CFCalendarIdentifier.hebrewCalendar), NSCalendarIdentifierHebrew)
        case .iso8601: return ("iso8601", cf(CFCalendarIdentifier.cfiso8601Calendar), NSCalendarIdentifierISO8601)
        case .indian: return ("indian", cf(CFCalendarIdentifier.indianCalendar), NSCalendarIdentifierIndian)
        case .islamic: return ("islamic", cf(CFCalendarIdentifier.islamicCalendar), NSCalendarIdentifierIslamic)
        case .islamicCivil: return ("islamic-civil", cf(CFCalendarIdentifier.islamicCivilCalendar), NSCalendarIdentifierIslamicCivil)
        case .japanese: return ("japanese", cf(CFCalendarIdentifier.japaneseCalendar), NSCalendarIdentifierJapanese)
        case .persian: return ("persian", cf(CFCalendarIdentifier.persianCalendar), NSCalendarIdentifierPersian)
        case .republicOfChina: return ("roc", cf(CFCalendarIdentifier.republicOfChinaCalendar), NSCalendarIdentifierRepublicOfChina)
        case .islamicTabular: return ("islamic-tbla", nil, NSCalendarIdentifierIslamicTabular)
        case .islamicUmmAlQura: return ("islamic-umalqura", nil, NSCalendarIdentifierIslamicUmmAlQura)
        }
    }

    private static let _identifiers: [Identifier] = [.gregorian, .buddhist, .chinese, .coptic, .ethiopicAmeteMihret, .ethiopicAmeteAlem, .hebrew, .iso8601, .indian, .islamic, .islamicCivil, .japanese, .persian, .republicOfChina, .islamicTabular, .islamicUmmAlQura]

    /// The identifier string Darling's NSCalendar and NSLocale accept for `identifier`.
    internal static func _toNSCalendarIdentifier(_ identifier: Identifier) -> String {
        let names = _names(identifier)
        return names.coreFoundation ?? names.foundation
    }

    internal static func _fromNSCalendarIdentifier(_ identifier: String) -> Identifier {
        for candidate in _identifiers {
            let names = _names(candidate)
            if identifier == names.apple || identifier == names.coreFoundation || identifier == names.foundation {
                return candidate
            }
        }
        return .gregorian
    }

    private static func _makeReference(_ identifier: Identifier) -> NSCalendar {
        let names = _names(identifier)
        for name in [names.coreFoundation, names.foundation, names.apple].compactMap({ $0 }) {
            if let calendar = NSCalendar(calendarIdentifier: name) {
                return calendar
            }
        }
        // Darling's CoreFoundation has no such calendar: fall back to the Gregorian one rather than crash.
        return NSCalendar(calendarIdentifier: _toNSCalendarIdentifier(.gregorian)) ?? (NSCalendar.currentCalendar() as! NSCalendar)
    }

    /// Copies a calendar with its settings; Darling's -copyWithZone: only keeps the identifier.
    private static func _copy(_ reference: NSCalendar) -> NSCalendar {
        let copy = NSCalendar(calendarIdentifier: reference.calendarIdentifier() ?? "")
            ?? _makeReference(_fromNSCalendarIdentifier(reference.calendarIdentifier() ?? ""))
        copy.setLocale(reference.locale())
        copy.setTimeZone(reference.timeZone())
        copy.setFirstWeekday(reference.firstWeekday())
        copy.setMinimumDaysInFirstWeek(reference.minimumDaysInFirstWeek())
        return copy
    }

    private static func _isAutoupdating(_ reference: NSCalendar) -> Bool {
        guard let cls = object_getClass(reference) else { return false }
        return String(cString: class_getName(cls)) == "NSAutoCalendar"
    }

    public static func ==(lhs: Calendar, rhs: Calendar) -> Bool {
        if lhs._autoupdating || rhs._autoupdating {
            return lhs._autoupdating == rhs._autoupdating
        } else {
            // NSCalendar's isEqual is broken (27019864) so we must implement this ourselves
            return lhs.identifier == rhs.identifier &&
                lhs.locale == rhs.locale &&
                lhs.timeZone == rhs.timeZone &&
                lhs.firstWeekday == rhs.firstWeekday &&
                lhs.minimumDaysInFirstWeek == rhs.minimumDaysInFirstWeek
        }
    }

}

extension Calendar : CustomDebugStringConvertible, CustomStringConvertible, CustomReflectable {
    private var _kindDescription : String {
        if _autoupdating {
            return "autoupdatingCurrent"
        } else if self == Calendar.current {
            return "current"
        } else {
            return "fixed"
        }
    }

    public var description: String {
        return "\(identifier) (\(_kindDescription))"
    }

    public var debugDescription : String {
        return "\(identifier) (\(_kindDescription))"
    }

    public var customMirror : Mirror {
        let c: [(label: String?, value: Any)] = [
          ("identifier", identifier),
          ("kind", _kindDescription),
          ("locale", locale as Any),
          ("timeZone", timeZone),
          ("firstWeekday", firstWeekday),
          ("minimumDaysInFirstWeek", minimumDaysInFirstWeek),
        ]
        return Mirror(self, children: c, displayStyle: Mirror.DisplayStyle.struct)
    }
}

extension Calendar : _ObjectiveCBridgeable {
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSCalendar {
        return _autoupdating ? _box.reference : Calendar._copy(_box.reference)
    }

    public static func _forceBridgeFromObjectiveC(_ input: NSCalendar, result: inout Calendar?) {
        if !_conditionallyBridgeFromObjectiveC(input, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ input: NSCalendar, result: inout Calendar?) -> Bool {
        result = Calendar(reference: input)
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSCalendar?) -> Calendar {
        var result: Calendar?
        _forceBridgeFromObjectiveC(source!, result: &result)
        return result!
    }
}

extension NSCalendar : _HasCustomAnyHashableRepresentation {
    // Must be @nonobjc to avoid infinite recursion during bridging.
    @nonobjc
    public func _toCustomAnyHashable() -> AnyHashable? {
        return AnyHashable(self as Calendar)
    }
}

extension Calendar : Codable {
    private enum CodingKeys : Int, CodingKey {
        case identifier
        case locale
        case timeZone
        case firstWeekday
        case minimumDaysInFirstWeek
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifierString = try container.decode(String.self, forKey: .identifier)
        let identifier = Calendar._fromNSCalendarIdentifier(identifierString)
        self.init(identifier: identifier)

        self.locale = try container.decodeIfPresent(Locale.self, forKey: .locale)
        self.timeZone = try container.decode(TimeZone.self, forKey: .timeZone)
        self.firstWeekday = try container.decode(Int.self, forKey: .firstWeekday)
        self.minimumDaysInFirstWeek = try container.decode(Int.self, forKey: .minimumDaysInFirstWeek)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Apple's identifier strings, so archives match macOS.
        try container.encode(Calendar._names(self.identifier).apple, forKey: .identifier)
        try container.encode(self.locale, forKey: .locale)
        try container.encode(self.timeZone, forKey: .timeZone)
        try container.encode(self.firstWeekday, forKey: .firstWeekday)
        try container.encode(self.minimumDaysInFirstWeek, forKey: .minimumDaysInFirstWeek)
    }
}
