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

// NSNumber bridging for the integer, floating-point, Bool and CGFloat types, and NSNumber's literal initializers, from
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
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
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
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
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
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
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
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
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
        if NSNumber(value: 1) == number {
            self = true
        } else if NSNumber(value: 0) == number {
            self = false
        } else {
            return nil
        }
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
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

extension UInt8 : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: __shared NSNumber) {
        self = number.unsignedCharValue()
    }

    public init(truncating number: __shared NSNumber) {
        self = number.unsignedCharValue()
    }

    public init?(exactly number: __shared NSNumber) {
        let value = number.unsignedCharValue()
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt8?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt8?) -> Bool {
        guard let value = UInt8(exactly: x) else { return false }
        result = value
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> UInt8 {
        var result: UInt8?
        guard let src = source else { return UInt8(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return UInt8(0) }
        return result!
    }
}

extension Int16 : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: __shared NSNumber) {
        self = number.shortValue()
    }

    public init(truncating number: __shared NSNumber) {
        self = number.shortValue()
    }

    public init?(exactly number: __shared NSNumber) {
        let value = number.shortValue()
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Int16?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Int16?) -> Bool {
        guard let value = Int16(exactly: x) else { return false }
        result = value
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Int16 {
        var result: Int16?
        guard let src = source else { return Int16(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return Int16(0) }
        return result!
    }
}

extension UInt16 : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: __shared NSNumber) {
        self = number.unsignedShortValue()
    }

    public init(truncating number: __shared NSNumber) {
        self = number.unsignedShortValue()
    }

    public init?(exactly number: __shared NSNumber) {
        let value = number.unsignedShortValue()
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt16?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt16?) -> Bool {
        guard let value = UInt16(exactly: x) else { return false }
        result = value
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> UInt16 {
        var result: UInt16?
        guard let src = source else { return UInt16(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return UInt16(0) }
        return result!
    }
}

extension Int32 : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: __shared NSNumber) {
        self = number.intValue()
    }

    public init(truncating number: __shared NSNumber) {
        self = number.intValue()
    }

    public init?(exactly number: __shared NSNumber) {
        let value = number.intValue()
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Int32?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Int32?) -> Bool {
        guard let value = Int32(exactly: x) else { return false }
        result = value
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Int32 {
        var result: Int32?
        guard let src = source else { return Int32(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return Int32(0) }
        return result!
    }
}

extension UInt32 : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: __shared NSNumber) {
        self = number.unsignedIntValue()
    }

    public init(truncating number: __shared NSNumber) {
        self = number.unsignedIntValue()
    }

    public init?(exactly number: __shared NSNumber) {
        let value = number.unsignedIntValue()
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt32?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt32?) -> Bool {
        guard let value = UInt32(exactly: x) else { return false }
        result = value
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> UInt32 {
        var result: UInt32?
        guard let src = source else { return UInt32(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return UInt32(0) }
        return result!
    }
}

extension UInt64 : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: __shared NSNumber) {
        self = number.unsignedLongLongValue()
    }

    public init(truncating number: __shared NSNumber) {
        self = number.unsignedLongLongValue()
    }

    public init?(exactly number: __shared NSNumber) {
        let value = number.unsignedLongLongValue()
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt64?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt64?) -> Bool {
        guard let value = UInt64(exactly: x) else { return false }
        result = value
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> UInt64 {
        var result: UInt64?
        guard let src = source else { return UInt64(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return UInt64(0) }
        return result!
    }
}

extension UInt : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: __shared NSNumber) {
        self = number.unsignedIntegerValue()
    }

    public init(truncating number: __shared NSNumber) {
        self = number.unsignedIntegerValue()
    }

    public init?(exactly number: __shared NSNumber) {
        let value = number.unsignedIntegerValue()
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt?) -> Bool {
        guard let value = UInt(exactly: x) else { return false }
        result = value
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> UInt {
        var result: UInt?
        guard let src = source else { return UInt(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return UInt(0) }
        return result!
    }
}

extension Float : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: __shared NSNumber) {
        self = number.floatValue()
    }

    public init(truncating number: __shared NSNumber) {
        self = number.floatValue()
    }

    public init?(exactly number: __shared NSNumber) {
        // Unsigned ('I', 'L', 'Q') and signed ('i', 'l', 'q') integer encodings are checked through 64-bit values.
        let type = number.objCType().pointee
        if type == 0x49 || type == 0x4c || type == 0x51 {
            guard let result = Float(exactly: number.unsignedLongLongValue()) else { return nil }
            self = result
        } else if type == 0x69 || type == 0x6c || type == 0x71 {
            guard let result = Float(exactly: number.longLongValue()) else { return nil }
            self = result
        } else {
            guard let result = Float(exactly: number.doubleValue()) else { return nil }
            self = result
        }
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Float?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Float?) -> Bool {
        if x.floatValue().isNaN {
            result = x.floatValue()
            return true
        }
        result = Float(exactly: x)
        return result != nil
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Float {
        var result: Float?
        guard let src = source else { return Float(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return Float(0) }
        return result!
    }
}

extension CGFloat : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: __shared NSNumber) {
        self.init(CGFloat.NativeType(truncating: number))
    }

    public init(truncating number: __shared NSNumber) {
        self.init(CGFloat.NativeType(truncating: number))
    }

    public init?(exactly number: __shared NSNumber) {
        var nativeValue: CGFloat.NativeType? = 0
        guard CGFloat.NativeType._conditionallyBridgeFromObjectiveC(number, result: &nativeValue) else { return nil }
        self.init(nativeValue!)
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNumber {
        return self.native._bridgeToObjectiveC()
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout CGFloat?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout CGFloat?) -> Bool {
        var nativeValue: CGFloat.NativeType? = 0
        guard CGFloat.NativeType._conditionallyBridgeFromObjectiveC(x, result: &nativeValue) else { return false }
        result = CGFloat(nativeValue!)
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> CGFloat {
        var result: CGFloat?
        guard let src = source else { return CGFloat(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return CGFloat(0) }
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
        // Booleans first: +numberWithBool: returns the kCFBoolean singletons, which must hash like Bool, not Int64.
        if self === kCFBooleanTrue {
            return AnyHashable(true)
        }
        if self === kCFBooleanFalse {
            return AnyHashable(false)
        }
        let int64Value = longLongValue()
        if NSNumber(value: int64Value) == self {
            return AnyHashable(int64Value)
        }
        let doubleValue = doubleValue()
        if NSNumber(value: doubleValue) == self {
            return AnyHashable(doubleValue)
        }
        return nil
    }
}

extension NSNumber : ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral {
    /// Create an instance initialized to `value`.
    @nonobjc
    public required convenience init(integerLiteral value: Int) {
        self.init(value: value)
    }

    /// Create an instance initialized to `value`.
    @nonobjc
    public required convenience init(floatLiteral value: Double) {
        self.init(value: value)
    }

    /// Create an instance initialized to `value`.
    @nonobjc
    public required convenience init(booleanLiteral value: Bool) {
        self.init(value: value)
    }
}

extension NSNumber {
    /// Box a Core Graphics floating-point value as a number.
    @nonobjc
    public convenience init(value: CGFloat) {
        self.init(double: Double(value))
    }
}
