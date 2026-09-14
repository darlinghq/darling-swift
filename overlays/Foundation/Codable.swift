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

// From release/5.4 stdlib/public/Darwin/Foundation/Codable.swift.
// Darling: there is no Combine overlay, so the TopLevelEncoder/TopLevelDecoder conformances are left out, and
// _typeDescription also describes the JSON box for integers above Int64.max as a number.

@_exported import Foundation // Clang module

//===----------------------------------------------------------------------===//
// Errors
//===----------------------------------------------------------------------===//

// Both of these error types bridge to NSError, and through the entry points they use, no further work is needed to make them localized.
extension EncodingError : LocalizedError {}
extension DecodingError : LocalizedError {}

//===----------------------------------------------------------------------===//
// Error Utilities
//===----------------------------------------------------------------------===//

extension DecodingError {
    /// Returns a `.typeMismatch` error describing the expected type.
    ///
    /// - parameter path: The path of `CodingKey`s taken to decode a value of this type.
    /// - parameter expectation: The type expected to be encountered.
    /// - parameter reality: The value that was encountered instead of the expected type.
    /// - returns: A `DecodingError` with the appropriate path and debug description.
    internal static func _typeMismatch(at path: [CodingKey], expectation: Any.Type, reality: Any) -> DecodingError {
        let description = "Expected to decode \(expectation) but found \(_typeDescription(of: reality)) instead."
        return .typeMismatch(expectation, Context(codingPath: path, debugDescription: description))
    }

    /// Returns a description of the type of `value` appropriate for an error message.
    ///
    /// - parameter value: The value whose type to describe.
    /// - returns: A string describing `value`.
    /// - precondition: `value` is one of the types below.
    private static func _typeDescription(of value: Any) -> String {
        if value is NSNull {
            return "a null value"
        } else if value is NSNumber || value is _JSONUnsignedNumber {
            return "a number"
        } else if value is String {
            return "a string/data"
        } else if value is [Any] {
            return "an array"
        } else if value is [String : Any] {
            return "a dictionary"
        } else {
            return "\(type(of: value))"
        }
    }
}

//===----------------------------------------------------------------------===//
// Number Utilities
//===----------------------------------------------------------------------===//

/// CoreFoundation's private 128-bit integer number type (CFSInt128Struct), which property lists use for
/// integers above Int64.max.
internal struct _CFSInt128 {
    var high: Int64
    var low: UInt64
}
internal let _kCFNumberSInt128Type = CFNumberType(rawValue: 17)!

/// The number's value as `T`, if it is exactly representable.
internal func _exactly<T : BinaryInteger>(_ number: NSNumber, as type: T.Type) -> T? {
    switch number.objCType().map({ String(cString: $0) }) ?? "" {
    case "f", "d":
        return T(exactly: number.doubleValue())
    case "":
        // Darling's __NSCFNumber reports no type encoding for 128-bit integers (UInt64 values above Int64.max in
        // property lists). JSON integers above Int64.max arrive as _JSONUnsignedNumber instead.
        var wide = _CFSInt128(high: 0, low: 0)
        guard CFNumberGetValue(unsafeBitCast(number, to: CFNumber.self), _kCFNumberSInt128Type, &wide) else { return nil }
        // CoreFoundation only creates 128-bit numbers for values above Int64.max.
        guard wide.high == 0 else { return nil }
        return T(exactly: wide.low)
    default:
        return T(exactly: number.longLongValue())
    }
}
