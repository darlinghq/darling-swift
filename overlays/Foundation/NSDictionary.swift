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

// From release/5.4 (apple/swift 845205b4407c) stdlib/public/Darwin/Foundation/NSDictionary.swift: the parts not already in
// Dictionary.swift and NSDictionary+Literal.swift of this overlay.
// Darling: NSDictionary.init(dictionary:) copies through allKeys/object(forKey:) because the original uses an
// overlay shim around -getObjects:andKeys:count:.

@_exported import Foundation // Clang module

// We don't check for NSCopying here for performance reasons. We would
// just crash anyway, and NSMutableDictionary will still do that when
// it tries to call -copyWithZone: and it's not there
private func duckCastToNSCopying(_ x: Any) -> NSCopying {
  return _unsafeReferenceCast(x as AnyObject, to: NSCopying.self)
}

extension NSDictionary : Sequence {
  // FIXME: A class because we can't pass a struct with class fields through an
  // [objc] interface without prematurely destroying the references.
  // NOTE: older runtimes had
  // _TtCE10FoundationCSo12NSDictionary8Iterator as the ObjC name. The
  // two must coexist, so it was renamed. The old name must not be used
  // in the new runtime.
  @_objcRuntimeName(_TtCE10FoundationCSo12NSDictionary9_Iterator)
  final public class Iterator : IteratorProtocol {
    var _fastIterator: NSFastEnumerationIterator
    var _dictionary: NSDictionary {
      return _fastIterator.enumerable as! NSDictionary
    }

    public func next() -> (key: Any, value: Any)? {
      if let key = _fastIterator.next() {
        // Deliberately avoid the subscript operator in case the dictionary
        // contains non-copyable keys. This is rare since NSMutableDictionary
        // requires them, but we don't want to paint ourselves into a corner.
        return (key: key, value: _dictionary.object(forKey: key)!)
      }
      return nil
    }

    internal init(_ _dict: __shared NSDictionary) {
      _fastIterator = NSFastEnumerationIterator(_dict)
    }
  }

  // Bridging subscript.
  @objc
  public subscript(key: Any) -> Any? {
    @objc(__swift_objectForKeyedSubscript:)
    get {
      // Deliberately avoid the subscript operator in case the dictionary
      // contains non-copyable keys. This is rare since NSMutableDictionary
      // requires them, but we don't want to paint ourselves into a corner.
      return self.object(forKey: key)
    }
  }

  /// Return an *iterator* over the elements of this *sequence*.
  ///
  /// - Complexity: O(1).
  public func makeIterator() -> Iterator {
    return Iterator(self)
  }
}

extension NSMutableDictionary {
  // Bridging subscript.
  @objc override public subscript(key: Any) -> Any? {
    @objc(__swift_objectForKeyedSubscript:)
    get {
      return self.object(forKey: key)
    }
    @objc(__swift_setObject:forKeyedSubscript:)
    set {
      let copyingKey = duckCastToNSCopying(key)
      if let newValue = newValue {
        self.setObject(newValue, forKey: copyingKey)
      } else {
        self.removeObject(forKey: copyingKey)
      }
    }
  }
}

extension NSDictionary {
  /// Initializes a newly allocated dictionary and adds to it objects from
  /// another given dictionary.
  ///
  /// - Returns: An initialized dictionary--which might be different
  ///   than the original receiver--containing the keys and values
  ///   found in `otherDictionary`.
  @objc(__swiftInitWithDictionary_NSDictionary:)
  public convenience init(dictionary otherDictionary: __shared NSDictionary) {
    let keys: [Any] = otherDictionary.allKeys() ?? []
    let values: [Any] = keys.map { otherDictionary.object(forKey: $0)! }
    self.init(objects: values, forKeys: keys.map { duckCastToNSCopying($0) } as [Any])
  }
}

extension NSDictionary : CustomReflectable {
  public var customMirror: Mirror {
    return Mirror(reflecting: self as [NSObject : AnyObject])
  }
}
