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

// Array <-> NSArray bridging, from release/5.4 stdlib/public/Darwin/Foundation/NSArray.swift.
// Only the _ObjectiveCBridgeable conformance is kept; Darling's NSArray has no Swift annotations.

@_exported import Foundation // Clang module
@_spi(Foundation) import Swift

extension Array : _ObjectiveCBridgeable {

  /// Private initializer used for bridging.
  ///
  /// The provided `NSArray` will be copied to ensure that the copy can
  /// not be mutated by other code.
  internal init(_cocoaArray: __shared NSArray) {
    assert(_isBridgedVerbatimToObjectiveC(Element.self),
      "Array can be backed by NSArray only when the element type can be bridged verbatim to Objective-C")
    self = Array(_immutableCocoaArray: _cocoaArray.copy() as AnyObject)
  }

  @_semantics("convertToObjectiveC")
  public func _bridgeToObjectiveC() -> NSArray {
    return unsafeBitCast(self._bridgeToObjectiveCImpl(), to: NSArray.self)
  }

  public static func _forceBridgeFromObjectiveC(
    _ source: NSArray,
    result: inout Array?
  ) {
    // If we have the appropriate native storage already, just adopt it.
    if let native =
        Array._bridgeFromObjectiveCAdoptingNativeStorageOf(source) {
      result = native
      return
    }

    if _fastPath(_isBridgedVerbatimToObjectiveC(Element.self)) {
      // Forced down-cast (possible deferred type-checking)
      result = Array(_cocoaArray: source)
      return
    }

    result = _arrayForceCast([AnyObject](_cocoaArray: source))
  }

  public static func _conditionallyBridgeFromObjectiveC(
    _ source: NSArray,
    result: inout Array?
  ) -> Bool {
    // Construct the result array by conditionally bridging each element.
    let anyObjectArr = [AnyObject](_cocoaArray: source)

    result = _arrayConditionalCast(anyObjectArr)
    return result != nil
  }

  @_effects(readonly)
  public static func _unconditionallyBridgeFromObjectiveC(
    _ source: NSArray?
  ) -> Array {
    // `nil` has historically been used as a stand-in for an empty
    // array; map it to an empty array instead of failing.
    if _slowPath(source == nil) { return Array() }

    // If we have the appropriate native storage already, just adopt it.
    if let native =
        Array._bridgeFromObjectiveCAdoptingNativeStorageOf(source!) {
      return native
    }

    if _fastPath(_isBridgedVerbatimToObjectiveC(Element.self)) {
      // Forced down-cast (possible deferred type-checking)
      return Array(_cocoaArray: source!)
    }

    return _arrayForceCast([AnyObject](_cocoaArray: source!))
  }
}
