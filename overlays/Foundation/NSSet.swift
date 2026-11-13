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

// From release/5.4 (apple/swift 845205b4407c) stdlib/public/Darwin/Foundation/NSSet.swift: the parts not already in
// Set.swift of this overlay. Darling: NSSet.init(set:) goes through allObjects instead of CFSetGetValues.

@_exported import Foundation // Clang module

extension NSSet : Sequence {
  /// Return an *iterator* over the elements of this *sequence*.
  ///
  /// - Complexity: O(1).
  public func makeIterator() -> NSFastEnumerationIterator {
    return NSFastEnumerationIterator(self)
  }
}

extension NSOrderedSet : Sequence {
  /// Return an *iterator* over the elements of this *sequence*.
  ///
  /// - Complexity: O(1).
  public func makeIterator() -> NSFastEnumerationIterator {
    return NSFastEnumerationIterator(self)
  }
}


extension NSOrderedSet {
  // - (instancetype)initWithObjects:(id)firstObj, ...
  public convenience init(objects elements: Any...) {
    self.init(array: elements)
  }
}

extension NSSet {
  // - (instancetype)initWithObjects:(id)firstObj, ...
  public convenience init(objects elements: Any...) {
    self.init(array: elements)
  }
}

extension NSSet : ExpressibleByArrayLiteral {
  public required convenience init(arrayLiteral elements: Any...) {
    self.init(array: elements)
  }
}

extension NSOrderedSet : ExpressibleByArrayLiteral {
  public required convenience init(arrayLiteral elements: Any...) {
    self.init(array: elements)
  }
}


extension NSSet {
  /// Initializes a newly allocated set and adds to it objects from
  /// another given set.
  ///
  /// - Returns: An initialized objects set containing the objects from
  ///   `set`. The returned set might be different than the original
  ///   receiver.
  @nonobjc
  public convenience init(set anSet: __shared NSSet) {
    self.init(array: anSet.allObjects())
  }
}

extension NSSet : CustomReflectable {
  public var customMirror: Mirror {
    return Mirror(reflecting: self as Set<NSObject>)
  }
}


