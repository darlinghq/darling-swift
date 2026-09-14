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

// Error <-> NSError bridging, from release/5.4 stdlib/public/Darwin/Foundation/NSError.swift. The error code tables
// (CocoaError, URLError, POSIXError, MachError) are not included.
// Darling: NSError's accessors are methods in Darling's headers, the user-info value provider and
// NSErrorRecoveryAttempting support are omitted (default user info is filled in eagerly), and CFError's conformance
// goes through its toll-free NSError.

@_exported import Foundation // Clang module
import CoreFoundation

public typealias NSErrorPointer = AutoreleasingUnsafeMutablePointer<NSError?>?

// Note: NSErrorPointer becomes ErrorPointer in Swift 3.
public typealias ErrorPointer = NSErrorPointer

// An error value to use when an Objective-C API indicates error
// but produces a nil error object.
internal enum _GenericObjCError : Error {
  case nilError
}
// A cached instance of the above in order to save on the conversion to Error.
private let _nilObjCError: Error = _GenericObjCError.nilError

public // COMPILER_INTRINSIC
func _convertNSErrorToError(_ error: NSError?) -> Error {
  if let error = error {
    return error
  }
  return _nilObjCError
}

public // COMPILER_INTRINSIC
func _convertErrorToNSError(_ error: Error) -> NSError {
  return unsafeDowncast(_bridgeErrorToNSError(error), to: NSError.self)
}

/// Describes an error that provides localized messages describing why
/// an error occurred and provides more information about the error.
public protocol LocalizedError : Error {
  /// A localized message describing what error occurred.
  var errorDescription: String? { get }

  /// A localized message describing the reason for the failure.
  var failureReason: String? { get }

  /// A localized message describing how one might recover from the failure.
  var recoverySuggestion: String? { get }

  /// A localized message providing "help" text if the user requests help.
  var helpAnchor: String? { get }
}

public extension LocalizedError {
  var errorDescription: String? { return nil }
  var failureReason: String? { return nil }
  var recoverySuggestion: String? { return nil }
  var helpAnchor: String? { return nil }
}

/// Describes an error that may be recoverable by presenting several
/// potential recovery options to the user.
public protocol RecoverableError : Error {
  /// Provides a set of possible recovery options to present to the user.
  var recoveryOptions: [String] { get }

  /// Attempt to recover from this error when the user selected the
  /// option at the given index. This routine must call handler and
  /// indicate whether recovery was successful (or not).
  func attemptRecovery(optionIndex recoveryOptionIndex: Int,
                       resultHandler handler: @escaping (_ recovered: Bool) -> Void)

  /// Attempt to recover from this error when the user selected the
  /// option at the given index. Returns true to indicate
  /// successful recovery, and false otherwise.
  func attemptRecovery(optionIndex recoveryOptionIndex: Int) -> Bool
}

public extension RecoverableError {
  /// Default implementation that uses the application-model recovery
  /// mechanism (``attemptRecovery(optionIndex:)``) to implement
  /// document-modal recovery.
  func attemptRecovery(optionIndex recoveryOptionIndex: Int,
                       resultHandler handler: @escaping (_ recovered: Bool) -> Void) {
    handler(attemptRecovery(optionIndex: recoveryOptionIndex))
  }
}

/// Describes an error type that specifically provides a domain, code,
/// and user-info dictionary.
public protocol CustomNSError : Error {
  /// The domain of the error.
  static var errorDomain: String { get }

  /// The error code within the given domain.
  var errorCode: Int { get }

  /// The user-info dictionary.
  var errorUserInfo: [String : Any] { get }
}

public extension CustomNSError {
  /// Default domain of the error.
  static var errorDomain: String {
    return String(reflecting: self)
  }

  /// The error code within the given domain.
  var errorCode: Int {
    return _getDefaultErrorCode(self)
  }

  /// The default user-info dictionary.
  var errorUserInfo: [String : Any] {
    return [:]
  }
}

/// Convert an arbitrary binary integer to an Int, reinterpreting signed
/// -> unsigned if needed but trapping if the result is otherwise not
/// expressible.
func unsafeBinaryIntegerToInt<T: BinaryInteger>(_ value: T) -> Int {
    if T.isSigned {
        return numericCast(value)
    }

    let uintValue: UInt = numericCast(value)
    return Int(bitPattern: uintValue)
}

/// Convert from an Int to an arbitrary binary integer, reinterpreting signed ->
/// unsigned if needed but trapping if the result is otherwise not expressible.
func unsafeBinaryIntegerFromInt<T: BinaryInteger>(_ value: Int) -> T {
  if T.isSigned {
    return numericCast(value)
  }

  let uintValue = UInt(bitPattern: value)
  return numericCast(uintValue)
}

extension CustomNSError
    where Self: RawRepresentable, Self.RawValue: FixedWidthInteger {
  // The error code of Error with integral raw values is the raw value.
  public var errorCode: Int {
    return unsafeBinaryIntegerToInt(self.rawValue)
  }
}

public extension Error where Self : CustomNSError {
  /// Default implementation for customized NSErrors.
  var _domain: String { return Self.errorDomain }

  /// Default implementation for customized NSErrors.
  var _code: Int { return self.errorCode }
}

public extension Error where Self: CustomNSError, Self: RawRepresentable,
    Self.RawValue: FixedWidthInteger {
  /// Default implementation for customized NSErrors.
  var _code: Int { return self.errorCode }
}

public extension Error {
  /// Retrieve the localized description for this error.
  var localizedDescription: String {
    return (self as NSError).localizedDescription()
  }
}

/// Retrieve the default userInfo dictionary for a given error.
public func _getErrorDefaultUserInfo<T: Error>(_ error: T)
  -> AnyObject? {
  // Populate the user-info dictionary
  var result: [String : Any]

  // Initialize with custom user-info.
  if let customNSError = error as? CustomNSError {
    result = customNSError.errorUserInfo
  } else {
    result = [:]
  }

  // Handle localized errors.
  if let localizedError = error as? LocalizedError {
    if let description = localizedError.errorDescription {
      result[NSLocalizedDescriptionKey] = description
    }

    if let reason = localizedError.failureReason {
      result[NSLocalizedFailureReasonErrorKey] = reason
    }

    if let suggestion = localizedError.recoverySuggestion {
      result[NSLocalizedRecoverySuggestionErrorKey] = suggestion
    }

    if let helpAnchor = localizedError.helpAnchor {
      result[NSHelpAnchorErrorKey] = helpAnchor
    }
  }

  // Handle recoverable errors.
  if let recoverableError = error as? RecoverableError {
    result[NSLocalizedRecoveryOptionsErrorKey] =
      recoverableError.recoveryOptions
  }

  return result as AnyObject
}

// NSError and CFError conform to the standard Error protocol. Compiler
// magic allows this to be done as a "toll-free" conversion when an NSError
// or CFError is used as an Error existential.

extension NSError : Error {
  @nonobjc
  public var _domain: String { return domain() }

  @nonobjc
  public var _code: Int { return code() }

  @nonobjc
  public var _userInfo: AnyObject? { return userInfo() as NSDictionary? }

  /// The "embedded" NSError is itself.
  @nonobjc
  public func _getEmbeddedNSError() -> AnyObject? {
    return self
  }
}

extension CFError : Error {
  private var _asNSError: NSError { return unsafeBitCast(self, to: NSError.self) }

  public var _domain: String {
    return _asNSError._domain
  }

  public var _code: Int {
    return _asNSError._code
  }

  public var _userInfo: AnyObject? {
    return _asNSError._userInfo
  }

  /// The "embedded" NSError is itself.
  public func _getEmbeddedNSError() -> AnyObject? {
    return self
  }
}

/// An internal protocol to represent Swift error enums that map to standard
/// Cocoa NSError domains.
public protocol _ObjectiveCBridgeableError : Error {
  /// Produce a value of the error type corresponding to the given NSError,
  /// or return nil if it cannot be bridged.
  init?(_bridgedNSError: __shared NSError)
}

/// A hook for the runtime to use _ObjectiveCBridgeableError in order to
/// attempt an "errorTypeValue as? SomeError" cast.
///
/// If the bridge succeeds, the bridged value is written to the uninitialized
/// memory pointed to by 'out', and true is returned. Otherwise, 'out' is
/// left uninitialized, and false is returned.
public func _bridgeNSErrorToError<
  T : _ObjectiveCBridgeableError
>(_ error: NSError, out: UnsafeMutablePointer<T>) -> Bool {
  if let bridged = T(_bridgedNSError: error) {
    out.initialize(to: bridged)
    return true
  } else {
    return false
  }
}

/// Describes a raw representable type that is bridged to a particular
/// NSError domain.
///
/// This protocol is used primarily to generate the conformance to
/// _ObjectiveCBridgeableError for such an enum defined in Swift.
public protocol _BridgedNSError :
    _ObjectiveCBridgeableError, RawRepresentable, Hashable
    where Self.RawValue: FixedWidthInteger {
  /// The NSError domain to which this type is bridged.
  static var _nsErrorDomain: String { get }
}

extension _BridgedNSError {
  public var _domain: String { return Self._nsErrorDomain }
}

extension _BridgedNSError where Self.RawValue: FixedWidthInteger {
  public var _code: Int { return Int(rawValue) }

  public init?(_bridgedNSError: __shared NSError) {
    if _bridgedNSError.domain() != Self._nsErrorDomain {
      return nil
    }

    self.init(rawValue: RawValue(_bridgedNSError.code()))
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(_code)
  }
}

/// Describes a bridged error that stores the underlying NSError, so
/// it can be queried.
public protocol _BridgedStoredNSError :
     _ObjectiveCBridgeableError, CustomNSError, Hashable {
  /// The type of an error code.
  associatedtype Code: _ErrorCodeProtocol, RawRepresentable
  where Code.RawValue: FixedWidthInteger

  //// Retrieves the embedded NSError.
  var _nsError: NSError { get }

  /// Create a new instance of the error type with the given embedded
  /// NSError.
  ///
  /// The \c error must have the appropriate domain for this error
  /// type.
  init(_nsError error: NSError)
}

/// Various helper implementations for _BridgedStoredNSError
extension _BridgedStoredNSError {
  public var code: Code {
    return Code(rawValue: unsafeBinaryIntegerFromInt(_nsError.code()))!
  }

  /// Initialize an error within this domain with the given ``code``
  /// and ``userInfo``.
  public init(_ code: Code, userInfo: [String : Any] = [:]) {
    self.init(_nsError: NSError(domain: Self.errorDomain,
                                code: unsafeBinaryIntegerToInt(code.rawValue),
                                userInfo: userInfo))
  }

  /// The user-info dictionary for an error that was bridged from
  /// NSError.
  public var userInfo: [String : Any] { return errorUserInfo }
}

/// Implementation of _ObjectiveCBridgeableError for all _BridgedStoredNSErrors.
extension _BridgedStoredNSError {
  /// Default implementation of ``init(_bridgedNSError:)`` to provide
  /// bridging from NSError.
  public init?(_bridgedNSError error: NSError) {
    if error.domain() != Self.errorDomain {
      return nil
    }

    self.init(_nsError: error)
  }
}

/// Implementation of CustomNSError for all _BridgedStoredNSErrors.
public extension _BridgedStoredNSError {
  var errorCode: Int { return _nsError.code() }

  var errorUserInfo: [String : Any] {
    var result: [String : Any] = [:]
    for (key, value) in _nsError.userInfo() ?? [:] {
      if let key = key.base as? String {
        result[key] = value
      }
    }
    return result
  }
}

/// Implementation of Hashable for all _BridgedStoredNSErrors.
extension _BridgedStoredNSError {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(_nsError)
  }

  @_alwaysEmitIntoClient public var hashValue: Int {
    return _nsError.hashValue
  }
}

/// Describes the code of an error.
public protocol _ErrorCodeProtocol : Equatable {
  /// The corresponding error code.
  associatedtype _ErrorType: _BridgedStoredNSError where _ErrorType.Code == Self
}

extension _ErrorCodeProtocol {
  /// Allow one to match an error code against an arbitrary error.
  public static func ~=(match: Self, error: Error) -> Bool {
    guard let specificError = error as? Self._ErrorType else { return false }

    return match == specificError.code
  }
}

extension _BridgedStoredNSError {
  /// Retrieve the embedded NSError from a bridged, stored NSError.
  public func _getEmbeddedNSError() -> AnyObject? {
    return _nsError
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs._nsError.isEqual(rhs._nsError)
  }
}

extension _SwiftNewtypeWrapper where Self.RawValue == Error {
  @inlinable // FIXME(sil-serialize-all)
  public func _bridgeToObjectiveC() -> NSError {
    return rawValue as NSError
  }

  @inlinable // FIXME(sil-serialize-all)
  public static func _forceBridgeFromObjectiveC(
    _ source: NSError,
    result: inout Self?
  ) {
    result = Self(rawValue: source)
  }

  @inlinable // FIXME(sil-serialize-all)
  public static func _conditionallyBridgeFromObjectiveC(
    _ source: NSError,
    result: inout Self?
  ) -> Bool {
    result = Self(rawValue: source)
    return result != nil
  }

  @inlinable // FIXME(sil-serialize-all)
  @_effects(readonly)
  public static func _unconditionallyBridgeFromObjectiveC(
    _ source: NSError?
  ) -> Self {
    return Self(rawValue: _convertNSErrorToError(source))!
  }
}
