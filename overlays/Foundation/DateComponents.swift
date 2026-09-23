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

// DateComponents, from release/5.4 stdlib/public/Darwin/Foundation/DateComponents.swift.
// Darling: the values are stored in Swift and bridged to a fresh NSDateComponents on demand, because Darling's
// NSDateComponents has no -isEqual:/-hash (equality would be identity), it has no leap month, and it marks unset
// fields with INT_MAX rather than NSUndefinedDateComponent (NSIntegerMax).
// The calendar computations (date, isValidDate) go through Calendar.

@_exported import Foundation // Clang module

/**
 `DateComponents` encapsulates the components of a date in an extendable, structured manner.

 It is used to specify a date by providing the temporal components that make up a date and time in a particular calendar: hour, minutes, seconds, day, month, year, and so on. It can also be used to specify a duration of time, for example, 5 hours and 16 minutes. A `DateComponents` is not required to define all the component fields.

 When a new instance of `DateComponents` is created, the date components are set to `nil`.
*/
public struct DateComponents : ReferenceConvertible, Hashable, Equatable {
    public typealias ReferenceType = NSDateComponents

    /// Initialize a `DateComponents`, optionally specifying values for its fields.
    public init(calendar: Calendar? = nil,
         timeZone: TimeZone? = nil,
         era: Int? = nil,
         year: Int? = nil,
         month: Int? = nil,
         day: Int? = nil,
         hour: Int? = nil,
         minute: Int? = nil,
         second: Int? = nil,
         nanosecond: Int? = nil,
         weekday: Int? = nil,
         weekdayOrdinal: Int? = nil,
         quarter: Int? = nil,
         weekOfMonth: Int? = nil,
         weekOfYear: Int? = nil,
         yearForWeekOfYear: Int? = nil) {
        self.calendar = calendar
        self.timeZone = timeZone
        self.era = era
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
        self.nanosecond = nanosecond
        self.weekday = weekday
        self.weekdayOrdinal = weekdayOrdinal
        self.quarter = quarter
        self.weekOfMonth = weekOfMonth
        self.weekOfYear = weekOfYear
        self.yearForWeekOfYear = yearForWeekOfYear
    }

    // MARK: - Properties

    /// The `Calendar` used to interpret the other values in this structure.
    ///
    /// - note: API which uses `DateComponents` may have different behavior if this value is `nil`. For example, assuming the current calendar or ignoring certain values.
    public var calendar: Calendar?

    /// A time zone.
    /// - note: This value is interpreted in the context of the calendar in which it is used.
    public var timeZone: TimeZone?

    /// An era or count of eras.
    /// - note: This value is interpreted in the context of the calendar in which it is used.
    public var era: Int?

    /// A year or count of years.
    /// - note: This value is interpreted in the context of the calendar in which it is used.
    public var year: Int?

    /// A month or count of months.
    /// - note: This value is interpreted in the context of the calendar in which it is used.
    public var month: Int?

    /// A day or count of days.
    /// - note: This value is interpreted in the context of the calendar in which it is used.
    public var day: Int?

    /// An hour or count of hours.
    /// - note: This value is interpreted in the context of the calendar in which it is used.
    public var hour: Int?

    /// A minute or count of minutes.
    /// - note: This value is interpreted in the context of the calendar in which it is used.
    public var minute: Int?

    /// A second or count of seconds.
    /// - note: This value is interpreted in the context of the calendar in which it is used.
    public var second: Int?

    /// A nanosecond or count of nanoseconds.
    /// - note: This value is interpreted in the context of the calendar in which it is used.
    public var nanosecond: Int?

    /// A weekday or count of weekdays.
    /// - note: This value is interpreted in the context of the calendar in which it is used.
    public var weekday: Int?

    /// A weekday ordinal or count of weekday ordinals.
    /// Weekday ordinal units represent the position of the weekday within the next larger calendar unit, such as the month. For example, 2 is the weekday ordinal unit for the second Friday of the month.
    /// - note: This value is interpreted in the context of the calendar in which it is used.
    public var weekdayOrdinal: Int?

    /// A quarter or count of quarters.
    /// - note: This value is interpreted in the context of the calendar in which it is used.
    public var quarter: Int?

    /// A week of the month or a count of weeks of the month.
    /// - note: This value is interpreted in the context of the calendar in which it is used.
    public var weekOfMonth: Int?

    /// A week of the year or count of the weeks of the year.
    /// - note: This value is interpreted in the context of the calendar in which it is used.
    public var weekOfYear: Int?

    /// The ISO 8601 week-numbering year of the receiver.
    /// - note: This value is interpreted in the context of the calendar in which it is used.
    public var yearForWeekOfYear: Int?

    /// Set to true if these components represent a leap month.
    public var isLeapMonth: Bool?

    /// Returns a `Date` calculated from the current components using the `calendar` property.
    public var date: Date? {
        guard var calendar = calendar else { return nil }
        if let timeZone = timeZone {
            calendar.timeZone = timeZone
        }
        return calendar.date(from: self)
    }

    // MARK: - Generic Setter/Getters

    /// Set the value of one of the properties, using an enumeration value instead of a property name.
    ///
    /// The calendar and timeZone and isLeapMonth properties cannot be set by this method.
    @available(macOS 10.9, iOS 8.0, *)
    public mutating func setValue(_ value: Int?, for component: Calendar.Component) {
        switch component {
        case .era: era = value
        case .year: year = value
        case .month: month = value
        case .day: day = value
        case .hour: hour = value
        case .minute: minute = value
        case .second: second = value
        case .weekday: weekday = value
        case .weekdayOrdinal: weekdayOrdinal = value
        case .quarter: quarter = value
        case .weekOfMonth: weekOfMonth = value
        case .weekOfYear: weekOfYear = value
        case .yearForWeekOfYear: yearForWeekOfYear = value
        case .nanosecond: nanosecond = value
        case .calendar, .timeZone: break
        }
    }

    /// Returns the value of one of the properties, using an enumeration value instead of a property name.
    ///
    /// The calendar and timeZone and isLeapMonth property values cannot be retrieved by this method.
    @available(macOS 10.9, iOS 8.0, *)
    public func value(for component: Calendar.Component) -> Int? {
        switch component {
        case .era: return era
        case .year: return year
        case .month: return month
        case .day: return day
        case .hour: return hour
        case .minute: return minute
        case .second: return second
        case .weekday: return weekday
        case .weekdayOrdinal: return weekdayOrdinal
        case .quarter: return quarter
        case .weekOfMonth: return weekOfMonth
        case .weekOfYear: return weekOfYear
        case .yearForWeekOfYear: return yearForWeekOfYear
        case .nanosecond: return nanosecond
        case .calendar, .timeZone: return nil
        }
    }

    // MARK: -

    /// Returns true if the combination of properties which have been set in the receiver is a date which exists in the `calendar` property.
    ///
    /// This method is not appropriate for use on `DateComponents` values which are specifying relative quantities of calendar components.
    ///
    /// If the time zone property is set in the `DateComponents`, it is used.
    ///
    /// The calendar property must be set, or the result is always `false`.
    @available(macOS 10.9, iOS 8.0, *)
    public var isValidDate: Bool {
        guard let calendar = calendar else { return false }
        return isValidDate(in: calendar)
    }

    /// Returns true if the combination of properties which have been set in the receiver is a date which exists in the specified `Calendar`.
    ///
    /// This method is not appropriate for use on `DateComponents` values which are specifying relative quantities of calendar components.
    ///
    /// If the time zone property is set in the `DateComponents`, it is used.
    @available(macOS 10.9, iOS 8.0, *)
    public func isValidDate(in calendar: Calendar) -> Bool {
        var calendar = calendar
        if let timeZone = timeZone {
            calendar.timeZone = timeZone
        }
        // A date exists for these components if composing them and decomposing the result gives the same values.
        // (Not nanoseconds, which Darling rounds to milliseconds, nor quarters, which it computes as fiscal quarters.)
        guard let date = calendar.date(from: self) else { return false }
        let components = Calendar._settableComponents.filter { value(for: $0) != nil && $0 != .nanosecond && $0 != .quarter }
        let decomposed = calendar.dateComponents(Set(components), from: date)
        return components.allSatisfy { decomposed.value(for: $0) == value(for: $0) }
    }

    // MARK: - Bridging Helpers

    /// Darling's NSDateComponents marks unset fields with INT_MAX; Apple's use NSUndefinedDateComponent (NSIntegerMax).
    fileprivate static func _fromReference(_ value: Int) -> Int? {
        return value == Int(Int32.max) || value == Int.max ? nil : value
    }
}

extension DateComponents : CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    public var description: String {
        return self.customMirror.children.reduce("") {
            $0 + "\($1.label ?? ""): \($1.value) "
        }
    }

    public var debugDescription: String {
        return self.description
    }

    public var customMirror: Mirror {
        var c: [(label: String?, value: Any)] = []
        if let r = calendar { c.append((label: "calendar", value: r)) }
        if let r = timeZone { c.append((label: "timeZone", value: r)) }
        if let r = era { c.append((label: "era", value: r)) }
        if let r = year { c.append((label: "year", value: r)) }
        if let r = month { c.append((label: "month", value: r)) }
        if let r = day { c.append((label: "day", value: r)) }
        if let r = hour { c.append((label: "hour", value: r)) }
        if let r = minute { c.append((label: "minute", value: r)) }
        if let r = second { c.append((label: "second", value: r)) }
        if let r = nanosecond { c.append((label: "nanosecond", value: r)) }
        if let r = weekday { c.append((label: "weekday", value: r)) }
        if let r = weekdayOrdinal { c.append((label: "weekdayOrdinal", value: r)) }
        if let r = quarter { c.append((label: "quarter", value: r)) }
        if let r = weekOfMonth { c.append((label: "weekOfMonth", value: r)) }
        if let r = weekOfYear { c.append((label: "weekOfYear", value: r)) }
        if let r = yearForWeekOfYear { c.append((label: "yearForWeekOfYear", value: r)) }
        if let r = isLeapMonth { c.append((label: "isLeapMonth", value: r)) }
        return Mirror(self, children: c, displayStyle: Mirror.DisplayStyle.struct)
    }
}

// MARK: - Bridging

extension DateComponents : _ObjectiveCBridgeable {
    public static func _getObjectiveCType() -> Any.Type {
        return NSDateComponents.self
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSDateComponents {
        let result = NSDateComponents()
        if let calendar = calendar { result.setCalendar(calendar) }
        if let timeZone = timeZone { result.setTimeZone(timeZone) }
        if let era = era { result.setEra(era) }
        if let year = year { result.setYear(year) }
        if let month = month { result.setMonth(month) }
        if let day = day { result.setDay(day) }
        if let hour = hour { result.setHour(hour) }
        if let minute = minute { result.setMinute(minute) }
        if let second = second { result.setSecond(second) }
        // -nanosecond/-setNanosecond: exist in Darling's implementation but not its header.
        if let nanosecond = nanosecond { result.setValue(nanosecond as NSNumber, forKey: "nanosecond") }
        if let weekday = weekday { result.setWeekday(weekday) }
        if let weekdayOrdinal = weekdayOrdinal { result.setWeekdayOrdinal(weekdayOrdinal) }
        if let quarter = quarter { result.setQuarter(quarter) }
        if let weekOfMonth = weekOfMonth { result.setWeekOfMonth(weekOfMonth) }
        if let weekOfYear = weekOfYear { result.setWeekOfYear(weekOfYear) }
        if let yearForWeekOfYear = yearForWeekOfYear { result.setYearForWeekOfYear(yearForWeekOfYear) }
        return result
    }

    public static func _forceBridgeFromObjectiveC(_ dateComponents: NSDateComponents, result: inout DateComponents?) {
        if !_conditionallyBridgeFromObjectiveC(dateComponents, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ dateComponents: NSDateComponents, result: inout DateComponents?) -> Bool {
        var components = DateComponents()
        components.calendar = dateComponents.calendar()
        components.timeZone = dateComponents.timeZone()
        components.era = _fromReference(dateComponents.era())
        components.year = _fromReference(dateComponents.year())
        components.month = _fromReference(dateComponents.month())
        components.day = _fromReference(dateComponents.day())
        components.hour = _fromReference(dateComponents.hour())
        components.minute = _fromReference(dateComponents.minute())
        components.second = _fromReference(dateComponents.second())
        components.nanosecond = (dateComponents.value(forKey: "nanosecond") as? NSNumber).flatMap { _fromReference($0.integerValue()) }
        components.weekday = _fromReference(dateComponents.weekday())
        components.weekdayOrdinal = _fromReference(dateComponents.weekdayOrdinal())
        components.quarter = _fromReference(dateComponents.quarter())
        components.weekOfMonth = _fromReference(dateComponents.weekOfMonth())
        components.weekOfYear = _fromReference(dateComponents.weekOfYear())
        components.yearForWeekOfYear = _fromReference(dateComponents.yearForWeekOfYear())
        result = components
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSDateComponents?) -> DateComponents {
        guard let src = source else { return DateComponents() }
        var result: DateComponents?
        _forceBridgeFromObjectiveC(src, result: &result)
        return result!
    }
}

extension NSDateComponents : _HasCustomAnyHashableRepresentation {
    // Must be @nonobjc to avoid infinite recursion during bridging.
    @nonobjc
    public func _toCustomAnyHashable() -> AnyHashable? {
        return AnyHashable(self as DateComponents)
    }
}

extension DateComponents : Codable {
    private enum CodingKeys : Int, CodingKey {
        case calendar
        case timeZone
        case era
        case year
        case month
        case day
        case hour
        case minute
        case second
        case nanosecond
        case weekday
        case weekdayOrdinal
        case quarter
        case weekOfMonth
        case weekOfYear
        case yearForWeekOfYear
    }

    public init(from decoder: Decoder) throws {
        let container  = try decoder.container(keyedBy: CodingKeys.self)
        let calendar   = try container.decodeIfPresent(Calendar.self, forKey: .calendar)
        let timeZone   = try container.decodeIfPresent(TimeZone.self, forKey: .timeZone)
        let era        = try container.decodeIfPresent(Int.self, forKey: .era)
        let year       = try container.decodeIfPresent(Int.self, forKey: .year)
        let month      = try container.decodeIfPresent(Int.self, forKey: .month)
        let day        = try container.decodeIfPresent(Int.self, forKey: .day)
        let hour       = try container.decodeIfPresent(Int.self, forKey: .hour)
        let minute     = try container.decodeIfPresent(Int.self, forKey: .minute)
        let second     = try container.decodeIfPresent(Int.self, forKey: .second)
        let nanosecond = try container.decodeIfPresent(Int.self, forKey: .nanosecond)

        let weekday           = try container.decodeIfPresent(Int.self, forKey: .weekday)
        let weekdayOrdinal    = try container.decodeIfPresent(Int.self, forKey: .weekdayOrdinal)
        let quarter           = try container.decodeIfPresent(Int.self, forKey: .quarter)
        let weekOfMonth       = try container.decodeIfPresent(Int.self, forKey: .weekOfMonth)
        let weekOfYear        = try container.decodeIfPresent(Int.self, forKey: .weekOfYear)
        let yearForWeekOfYear = try container.decodeIfPresent(Int.self, forKey: .yearForWeekOfYear)

        self.init(calendar: calendar,
                  timeZone: timeZone,
                  era: era,
                  year: year,
                  month: month,
                  day: day,
                  hour: hour,
                  minute: minute,
                  second: second,
                  nanosecond: nanosecond,
                  weekday: weekday,
                  weekdayOrdinal: weekdayOrdinal,
                  quarter: quarter,
                  weekOfMonth: weekOfMonth,
                  weekOfYear: weekOfYear,
                  yearForWeekOfYear: yearForWeekOfYear)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.calendar, forKey: .calendar)
        try container.encodeIfPresent(self.timeZone, forKey: .timeZone)
        try container.encodeIfPresent(self.era, forKey: .era)
        try container.encodeIfPresent(self.year, forKey: .year)
        try container.encodeIfPresent(self.month, forKey: .month)
        try container.encodeIfPresent(self.day, forKey: .day)
        try container.encodeIfPresent(self.hour, forKey: .hour)
        try container.encodeIfPresent(self.minute, forKey: .minute)
        try container.encodeIfPresent(self.second, forKey: .second)
        try container.encodeIfPresent(self.nanosecond, forKey: .nanosecond)
        try container.encodeIfPresent(self.weekday, forKey: .weekday)
        try container.encodeIfPresent(self.weekdayOrdinal, forKey: .weekdayOrdinal)
        try container.encodeIfPresent(self.quarter, forKey: .quarter)
        try container.encodeIfPresent(self.weekOfMonth, forKey: .weekOfMonth)
        try container.encodeIfPresent(self.weekOfYear, forKey: .weekOfYear)
        try container.encodeIfPresent(self.yearForWeekOfYear, forKey: .yearForWeekOfYear)
    }
}
