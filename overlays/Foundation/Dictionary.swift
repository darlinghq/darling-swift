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

// Dictionary <-> NSDictionary bridging, from release/5.4 stdlib/public/Darwin/Foundation/NSDictionary.swift.
// Darling: non-verbatim dictionaries are always built through enumeration (the 5.4 slow path), which avoids the
// __NSDictionaryGetObjects overlay shim.

@_exported import Foundation // Clang module
@_spi(Foundation) import Swift

extension Dictionary {
  /// Private initializer used for bridging.
  ///
  /// The provided `NSDictionary` will be copied to ensure that the copy can
  /// not be mutated by other code.
  private init(_cocoaDictionary: __shared NSDictionary) {
    assert(
      _isBridgedVerbatimToObjectiveC(Key.self) &&
      _isBridgedVerbatimToObjectiveC(Value.self),
      "Dictionary can be backed by NSDictionary storage only when both key and value are bridged verbatim to Objective-C")
    self = Dictionary(
      _immutableCocoaDictionary: _cocoaDictionary.copy() as AnyObject)
  }
}

// Dictionary<Key, Value> is conditionally bridged to NSDictionary
extension Dictionary : _ObjectiveCBridgeable {
  @_semantics("convertToObjectiveC")
  public func _bridgeToObjectiveC() -> NSDictionary {
    return unsafeBitCast(_bridgeToObjectiveCImpl(),
                         to: NSDictionary.self)
  }

  public static func _forceBridgeFromObjectiveC(
    _ d: NSDictionary,
    result: inout Dictionary?
  ) {
    if let native = [Key : Value]._bridgeFromObjectiveCAdoptingNativeStorageOf(
        d as AnyObject) {
      result = native
      return
    }

    if _isBridgedVerbatimToObjectiveC(Key.self) &&
       _isBridgedVerbatimToObjectiveC(Value.self) {
      //Lazily type-checked on access
      result = [Key : Value](_cocoaDictionary: d)
      return
    }

    // Assign through the subscript: two distinct NSString keys can be equal Strings ("\u{E9}" and "e\u{301}"),
    // and _DictionaryBuilder doesn't allow duplicate keys.
    var dictionary = Dictionary<Key, Value>(minimumCapacity: d.count())
    d.enumerateKeysAndObjects({ anyKey, anyValue, _ in
      dictionary[anyKey as! Key] = (anyValue as! Value)
    })
    result = dictionary
  }

  public static func _conditionallyBridgeFromObjectiveC(
    _ x: NSDictionary,
    result: inout Dictionary?
  ) -> Bool {

    if let native = [Key : Value]._bridgeFromObjectiveCAdoptingNativeStorageOf(
        x as AnyObject) {
      result = native
      return true
    }

    result = x as [NSObject : AnyObject] as? Dictionary
    return result != nil
  }

  @_effects(readonly)
  public static func _unconditionallyBridgeFromObjectiveC(
    _ d: NSDictionary?
  ) -> Dictionary {
    // `nil` has historically been used as a stand-in for an empty
    // dictionary; map it to an empty dictionary.
    if _slowPath(d == nil) { return Dictionary() }

    var result: Dictionary? = nil
    _forceBridgeFromObjectiveC(d!, result: &result)
    return result!
  }
}
