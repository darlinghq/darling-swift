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

// NSLocalizedString, NSLog, NSNotFound, AnyHashable bridging and CVarArg for bridged types, from release/5.4
// stdlib/public/Darwin/Foundation/Foundation.swift, plus String(format:) from NSStringAPI.swift and the CVarArg
// conformances of the bridged collections.
// Darling: NSNotFound is a computed global (apps import its getter); the Locale-taking format
// initializers are omitted until there is a Locale overlay.

@_exported import Foundation // Clang module
@_spi(Foundation) import Swift

public var NSNotFound: Int { return .max }

public
func NSLocalizedString(_ key: String,
                       tableName: String? = nil,
                       bundle: Bundle = Bundle.main,
                       value: String = "",
                       comment: String) -> String {
  return bundle.localizedString(forKey: key, value: value, table: tableName)
}

public func NSLog(_ format: String, _ args: CVarArg...) {
  withVaList(args) { NSLogv(format, $0) }
}

extension AnyHashable : _ObjectiveCBridgeable {
  public func _bridgeToObjectiveC() -> NSObject {
    // This is unprincipled, but pretty much any object we'll encounter in
    // Swift is NSObject-conforming enough to have -hash and -isEqual:.
    return unsafeBitCast(base as AnyObject, to: NSObject.self)
  }

  public static func _forceBridgeFromObjectiveC(
    _ x: NSObject,
    result: inout AnyHashable?
  ) {
    result = AnyHashable(x)
  }

  public static func _conditionallyBridgeFromObjectiveC(
    _ x: NSObject,
    result: inout AnyHashable?
  ) -> Bool {
    self._forceBridgeFromObjectiveC(x, result: &result)
    return result != nil
  }

  @_effects(readonly)
  public static func _unconditionallyBridgeFromObjectiveC(
    _ source: NSObject?
  ) -> AnyHashable {
    // `nil` has historically been used as a stand-in for an empty
    // string; map it to an empty string.
    if _slowPath(source == nil) { return AnyHashable(String()) }
    return AnyHashable(source!)
  }
}

extension CVarArg where Self: _ObjectiveCBridgeable {
  /// Default implementation for bridgeable types.
  public var _cVarArgEncoding: [Int] {
    let object = self._bridgeToObjectiveC()
    _autorelease(object)
    return _encodeBitsAsWords(object)
  }
}

// Consistent AnyHashable semantics for bridged Objective-C values (from NSString.swift, NSArray.swift,
// NSDictionary.swift and NSSet.swift): an NSString key must hash and compare like the equivalent String.
extension NSString : _HasCustomAnyHashableRepresentation {
  // Must be @nonobjc to prevent infinite recursion trying to bridge
  // AnyHashable to NSObject.
  @nonobjc
  public func _toCustomAnyHashable() -> AnyHashable? {
    // Consistently use Swift equality and hashing semantics for all strings.
    return AnyHashable(self as String)
  }
}

extension NSArray : _HasCustomAnyHashableRepresentation {
  // Must be @nonobjc to avoid infinite recursion during bridging
  @nonobjc
  public func _toCustomAnyHashable() -> AnyHashable? {
    return AnyHashable(self as! Array<AnyHashable>)
  }
}

extension NSDictionary : _HasCustomAnyHashableRepresentation {
  // Must be @nonobjc to avoid infinite recursion during bridging
  @nonobjc
  public func _toCustomAnyHashable() -> AnyHashable? {
    return AnyHashable(self as! Dictionary<AnyHashable, AnyHashable>)
  }
}

extension NSSet : _HasCustomAnyHashableRepresentation {
  // Must be @nonobjc to avoid infinite recursion during bridging
  @nonobjc
  public func _toCustomAnyHashable() -> AnyHashable? {
    return AnyHashable(self as! Set<AnyHashable>)
  }
}

extension String: CVarArg {}
extension Array: CVarArg {}
extension Dictionary: CVarArg {}
extension Set: CVarArg {}

extension String {
  /// Returns a string created by using a given format string as a
  /// template into which the remaining argument values are substituted
  /// according to the user's default locale.
  public static func localizedStringWithFormat(
    _ format: String, _ arguments: CVarArg...
  ) -> String {
    return withVaList(arguments) {
      NSString(format: format, locale: NSLocale.currentLocale(), arguments: $0) as String
    }
  }

  /// Returns a `String` object initialized by using a given
  /// format string as a template into which the remaining argument
  /// values are substituted.
  public init(format: __shared String, _ arguments: CVarArg...) {
    self = String(format: format, arguments: arguments)
  }

  /// Returns a `String` object initialized by using a given
  /// format string as a template into which the remaining argument
  /// values are substituted.
  public init(format: __shared String, arguments: __shared [CVarArg]) {
    self = withVaList(arguments) {
      NSString(format: format, arguments: $0) as String
    }
  }
}
