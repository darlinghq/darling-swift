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

// Set <-> NSSet bridging, from release/5.4 stdlib/public/Darwin/Foundation/NSSet.swift.

@_exported import Foundation // Clang module
@_spi(Foundation) import Swift

extension Set {
  /// Private initializer used for bridging.
  ///
  /// The provided `NSSet` will be copied to ensure that the copy can
  /// not be mutated by other code.
  private init(_cocoaSet: __shared NSSet) {
    assert(_isBridgedVerbatimToObjectiveC(Element.self),
      "Set can be backed by NSSet _variantStorage only when the member type can be bridged verbatim to Objective-C")
    self = Set(_immutableCocoaSet: _cocoaSet.copy() as AnyObject)
  }
}

// Set<Element> is conditionally bridged to NSSet
extension Set : _ObjectiveCBridgeable {
  @_semantics("convertToObjectiveC")
  public func _bridgeToObjectiveC() -> NSSet {
    return unsafeBitCast(_bridgeToObjectiveCImpl(), to: NSSet.self)
  }

  public static func _forceBridgeFromObjectiveC(_ s: NSSet, result: inout Set?) {
    if let native =
      Set<Element>._bridgeFromObjectiveCAdoptingNativeStorageOf(s as AnyObject) {

      result = native
      return
    }

    if _isBridgedVerbatimToObjectiveC(Element.self) {
      result = Set<Element>(_cocoaSet: s)
      return
    }

    if Element.self == String.self {
      // String and NSString have different concepts of equality, so
      // string-keyed NSSets may generate key collisions when bridged over to
      // Swift. See rdar://problem/35995647
      var set = Set(minimumCapacity: s.count())
      s.enumerateObjects({ anyMember, _ in
        set.insert(anyMember as! Element)
      })
      result = set
      return
    }

    // `Set<Element>` where `Element` is a value type may not be backed by
    // an NSSet.
    var builder = _SetBuilder<Element>(count: s.count())
    s.enumerateObjects({ anyMember, _ in
      builder.add(member: anyMember as! Element)
    })
    result = builder.take()
  }

  public static func _conditionallyBridgeFromObjectiveC(
    _ x: NSSet, result: inout Set?
  ) -> Bool {
    let anySet = x as Set<NSObject>
    if _isBridgedVerbatimToObjectiveC(Element.self) {
      result = Swift._setDownCastConditional(anySet)
      return result != nil
    }

    result = anySet as? Set
    return result != nil
  }

  @_effects(readonly)
  public static func _unconditionallyBridgeFromObjectiveC(_ s: NSSet?) -> Set {
    // `nil` has historically been used as a stand-in for an empty
    // set; map it to an empty set.
    if _slowPath(s == nil) { return Set() }

    var result: Set? = nil
    Set<Element>._forceBridgeFromObjectiveC(s!, result: &result)
    return result!
  }
}
