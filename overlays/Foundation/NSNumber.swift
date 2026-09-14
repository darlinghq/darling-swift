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

// NSNumber bridging for the integer, Bool and Double types apps import, and NSNumber's literal initializers, from
// release/5.4 stdlib/public/Darwin/Foundation/NSNumber.swift.
// Darling: NSNumber's value accessors are methods and its initializers are init(integer:), init(bool:), ...; Bool's
// exact-value check compares against 0/1 instead of kCFBooleanTrue/kCFBooleanFalse identity.

@_exported import Foundation // Clang module

extension Int8 : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: __shared NSNumber) {
        self = number.charValue()
    }

    public init(truncating number: __shared NSNumber) {
        self = number.charValue()
    }

    public init?(exactly number: __shared NSNumber) {
        let value = number.charValue()
        guard NSNumber(char: value) == number else { return nil }
        self = value
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(char: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Int8?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Int8?) -> Bool {
        guard let value = Int8(exactly: x) else { return false }
        result = value
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Int8 {
        var result: Int8?
        guard let src = source else { return Int8(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return Int8(0) }
        return result!
    }
}

extension Int64 : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: __shared NSNumber) {
        self = number.longLongValue()
    }

    public init(truncating number: __shared NSNumber) {
        self = number.longLongValue()
    }

    public init?(exactly number: __shared NSNumber) {
        let value = number.longLongValue()
        guard NSNumber(longLong: value) == number else { return nil }
        self = value
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(longLong: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Int64?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Int64?) -> Bool {
        guard let value = Int64(exactly: x) else { return false }
        result = value
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Int64 {
        var result: Int64?
        guard let src = source else { return Int64(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return Int64(0) }
        return result!
    }
}

extension Int : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: __shared NSNumber) {
        self = number.integerValue()
    }

    public init(truncating number: __shared NSNumber) {
        self = number.integerValue()
    }

    public init?(exactly number: __shared NSNumber) {
        let value = number.integerValue()
        guard NSNumber(integer: value) == number else { return nil }
        self = value
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(integer: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Int?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Int?) -> Bool {
        guard let value = Int(exactly: x) else { return false }
        result = value
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Int {
        var result: Int?
        guard let src = source else { return Int(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return Int(0) }
        return result!
    }
}

extension Double : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: __shared NSNumber) {
        self = number.doubleValue()
    }

    public init(truncating number: __shared NSNumber) {
        self = number.doubleValue()
    }

    public init?(exactly number: __shared NSNumber) {
        let value = number.doubleValue()
        guard NSNumber(double: value) == number else { return nil }
        self = value
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(double: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Double?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Double?) -> Bool {
        // Any NSNumber converts to a Double (possibly losing precision), as in the 5.4 overlay's fallback.
        result = x.doubleValue()
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Double {
        var result: Double?
        guard let src = source else { return Double(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return Double(0) }
        return result!
    }
}

extension Bool : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: __shared NSNumber) {
        self = number.boolValue()
    }

    public init(truncating number: __shared NSNumber) {
        self = number.boolValue()
    }

    public init?(exactly number: __shared NSNumber) {
        if NSNumber(integer: 1) == number {
            self = true
        } else if NSNumber(integer: 0) == number {
            self = false
        } else {
            return nil
        }
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(bool: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Bool?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Bool?) -> Bool {
        guard let value = Bool(exactly: x) else { return false }
        result = value
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Bool {
        var result: Bool?
        guard let src = source else { return false }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return false }
        return result!
    }
}

extension NSNumber : _HasCustomAnyHashableRepresentation {
    // Must be @nonobjc to prevent infinite recursion trying to bridge
    // AnyHashable to NSObject.
    @nonobjc
    public func _toCustomAnyHashable() -> AnyHashable? {
        // Compare numbers through the largest box available (Int64, then Double), so that e.g.
        // ([Int : Any] as [AnyHashable : Any]) and [NSNumber : Any] agree. Darling: without a Decimal overlay,
        // NSDecimalNumber isn't special-cased.
        let int64Value = longLongValue()
        if NSNumber(longLong: int64Value) == self {
            return AnyHashable(int64Value)
        }
        let doubleValue = doubleValue()
        if NSNumber(double: doubleValue) == self {
            return AnyHashable(doubleValue)
        }
        return nil
    }
}

extension NSNumber : ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral {
    /// Create an instance initialized to `value`.
    @nonobjc
    public required convenience init(integerLiteral value: Int) {
        self.init(integer: value)
    }

    /// Create an instance initialized to `value`.
    @nonobjc
    public required convenience init(floatLiteral value: Double) {
        self.init(double: value)
    }

    /// Create an instance initialized to `value`.
    @nonobjc
    public required convenience init(booleanLiteral value: Bool) {
        self.init(bool: value)
    }
}
