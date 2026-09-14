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

// Date, from release/5.4 stdlib/public/Darwin/Foundation/Date.swift.
// Darling: TimeInterval and ComparisonResult are declared here (Darling's headers have no Swift names; they mangle
// as Swift.Double and __C.NSComparisonResult either way), NSDate's accessors are methods, description(with:) and
// the playground quick look are omitted, and Date.now, advanced(by:) and distance(to:) from newer SDKs are added.

@_exported import Foundation // Clang module
import CoreFoundation

public typealias TimeInterval = NSTimeInterval
public typealias ComparisonResult = NSComparisonResult

// Darling's NS_ENUM imports NSComparisonResult as a raw-value struct (it still mangles as __C.NSComparisonResult),
// so provide the Swift case names apps and the overlay use.
extension NSComparisonResult {
    public static var orderedAscending: NSComparisonResult { return NSComparisonResult(rawValue: -1) }
    public static var orderedSame: NSComparisonResult { return NSComparisonResult(rawValue: 0) }
    public static var orderedDescending: NSComparisonResult { return NSComparisonResult(rawValue: 1) }
}

/**
 `Date` represents a single point in time.

 A `Date` is independent of a particular calendar or time zone. To represent a `Date` to a user, you must interpret it in the context of a `Calendar`.
*/
public struct Date : ReferenceConvertible, Comparable, Equatable {
    public typealias ReferenceType = NSDate

    fileprivate var _time : TimeInterval

    /// The number of seconds from 1 January 1970 to the reference date, 1 January 2001.
    public static let timeIntervalBetween1970AndReferenceDate : TimeInterval = 978307200.0

    /// The interval between 00:00:00 UTC on 1 January 2001 and the current date and time.
    public static var timeIntervalSinceReferenceDate : TimeInterval {
        return CFAbsoluteTimeGetCurrent()
    }

    /// Returns a `Date` initialized to the current date and time.
    public init() {
        _time = CFAbsoluteTimeGetCurrent()
    }

    /// Returns a `Date` initialized relative to the current date and time by a given number of seconds.
    public init(timeIntervalSinceNow: TimeInterval) {
        self.init(timeIntervalSinceReferenceDate: timeIntervalSinceNow + CFAbsoluteTimeGetCurrent())
    }

    /// Returns a `Date` initialized relative to 00:00:00 UTC on 1 January 1970 by a given number of seconds.
    public init(timeIntervalSince1970: TimeInterval) {
        self.init(timeIntervalSinceReferenceDate: timeIntervalSince1970 - Date.timeIntervalBetween1970AndReferenceDate)
    }

    /**
    Returns a `Date` initialized relative to another given date by a given number of seconds.

    - Parameter timeInterval: The number of seconds to add to `date`. A negative value means the receiver will be earlier than `date`.
    - Parameter date: The reference date.
    */
    public init(timeInterval: TimeInterval, since date: Date) {
        self.init(timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate + timeInterval)
    }

    /// Returns a `Date` initialized relative to 00:00:00 UTC on 1 January 2001 by a given number of seconds.
    public init(timeIntervalSinceReferenceDate ti: TimeInterval) {
        _time = ti
    }

    /// The current date and time.
    public static var now: Date {
        return Date()
    }

    /**
    Returns the interval between the date object and 00:00:00 UTC on 1 January 2001.

    This property's value is negative if the date object is earlier than the system's absolute reference date (00:00:00 UTC on 1 January 2001).
    */
    public var timeIntervalSinceReferenceDate: TimeInterval {
        return _time
    }

    /**
    Returns the interval between the receiver and another given date.

    - Parameter another: The date with which to compare the receiver.

    - Returns: The interval between the receiver and the `another` parameter. If the receiver is earlier than `anotherDate`, the return value is negative.
    */
    public func timeIntervalSince(_ date: Date) -> TimeInterval {
        return self.timeIntervalSinceReferenceDate - date.timeIntervalSinceReferenceDate
    }

    /**
    The time interval between the date and the current date and time.

    If the date is earlier than the current date and time, this property's value is negative.
    */
    public var timeIntervalSinceNow: TimeInterval {
        return self.timeIntervalSinceReferenceDate - CFAbsoluteTimeGetCurrent()
    }

    /**
    The interval between the date object and 00:00:00 UTC on 1 January 1970.

    This property's value is negative if the date object is earlier than 00:00:00 UTC on 1 January 1970.
    */
    public var timeIntervalSince1970: TimeInterval {
        return self.timeIntervalSinceReferenceDate + Date.timeIntervalBetween1970AndReferenceDate
    }

    /// Return a new `Date` by adding a `TimeInterval` to this `Date`.
    ///
    /// - parameter timeInterval: The value to add, in seconds.
    public func addingTimeInterval(_ timeInterval: TimeInterval) -> Date {
        return self + timeInterval
    }

    /// Add a `TimeInterval` to this `Date`.
    ///
    /// - parameter timeInterval: The value to add, in seconds.
    public mutating func addTimeInterval(_ timeInterval: TimeInterval) {
        self += timeInterval
    }

    /// Returns the distance from this date to another date, in seconds.
    public func distance(to other: Date) -> TimeInterval {
        return other.timeIntervalSinceReferenceDate - self.timeIntervalSinceReferenceDate
    }

    /// Returns a date offset by the given number of seconds.
    public func advanced(by n: TimeInterval) -> Date {
        return self + n
    }

    /**
    Creates and returns a Date value representing a date in the distant future.

    The distant future is in terms of centuries.
    */
    public static let distantFuture = Date(timeIntervalSinceReferenceDate: 63113904000.0)

    /**
    Creates and returns a Date value representing a date in the distant past.

    The distant past is in terms of centuries.
    */
    public static let distantPast = Date(timeIntervalSinceReferenceDate: -63114076800.0)

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_time)
    }

    /// Compare two `Date` values.
    public func compare(_ other: Date) -> ComparisonResult {
        if _time < other.timeIntervalSinceReferenceDate {
            return .orderedAscending
        } else if _time > other.timeIntervalSinceReferenceDate {
            return .orderedDescending
        } else {
            return .orderedSame
        }
    }

    /// Returns true if the two `Date` values represent the same point in time.
    public static func ==(lhs: Date, rhs: Date) -> Bool {
        return lhs.timeIntervalSinceReferenceDate == rhs.timeIntervalSinceReferenceDate
    }

    /// Returns true if the left hand `Date` is earlier in time than the right hand `Date`.
    public static func <(lhs: Date, rhs: Date) -> Bool {
        return lhs.timeIntervalSinceReferenceDate < rhs.timeIntervalSinceReferenceDate
    }

    /// Returns true if the left hand `Date` is later in time than the right hand `Date`.
    public static func >(lhs: Date, rhs: Date) -> Bool {
        return lhs.timeIntervalSinceReferenceDate > rhs.timeIntervalSinceReferenceDate
    }

    /// Returns a `Date` with a specified amount of time added to it.
    public static func +(lhs: Date, rhs: TimeInterval) -> Date {
        return Date(timeIntervalSinceReferenceDate: lhs.timeIntervalSinceReferenceDate + rhs)
    }

    /// Returns a `Date` with a specified amount of time subtracted from it.
    public static func -(lhs: Date, rhs: TimeInterval) -> Date {
        return Date(timeIntervalSinceReferenceDate: lhs.timeIntervalSinceReferenceDate - rhs)
    }

    /// Add a `TimeInterval` to a `Date`.
    public static func +=(lhs: inout Date, rhs: TimeInterval) {
        lhs = lhs + rhs
    }

    /// Subtract a `TimeInterval` from a `Date`.
    public static func -=(lhs: inout Date, rhs: TimeInterval) {
        lhs = lhs - rhs
    }

}

extension Date : CustomDebugStringConvertible, CustomStringConvertible, CustomReflectable {
    /**
     A string representation of the date object (read-only).

     The representation is useful for debugging only.
     */
    public var description: String {
        // Defer to NSDate for description
        return NSDate(timeIntervalSinceReferenceDate: _time).description()
    }

    public var debugDescription: String {
        return description
    }

    public var customMirror: Mirror {
        let c: [(label: String?, value: Any)] = [
          ("timeIntervalSinceReferenceDate", timeIntervalSinceReferenceDate)
        ]
        return Mirror(self, children: c, displayStyle: Mirror.DisplayStyle.struct)
    }
}

extension Date : _ObjectiveCBridgeable {
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSDate {
        return NSDate(timeIntervalSinceReferenceDate: _time)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSDate, result: inout Date?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSDate, result: inout Date?) -> Bool {
        result = Date(timeIntervalSinceReferenceDate: x.timeIntervalSinceReferenceDate())
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSDate?) -> Date {
        var result: Date?
        _forceBridgeFromObjectiveC(source!, result: &result)
        return result!
    }
}

extension NSDate : _HasCustomAnyHashableRepresentation {
    // Must be @nonobjc to avoid infinite recursion during bridging.
    @nonobjc
    public func _toCustomAnyHashable() -> AnyHashable? {
        return AnyHashable(self as Date)
    }
}

extension Date : Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let timestamp = try container.decode(Double.self)
        self.init(timeIntervalSinceReferenceDate: timestamp)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.timeIntervalSinceReferenceDate)
    }
}
