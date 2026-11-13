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

// From release/5.4 (apple/swift 845205b4407c) stdlib/public/Darwin/Foundation/NSArray.swift: the parts not already in
// Array.swift and NSFastEnumeration.swift of this overlay.

@_exported import Foundation // Clang module

extension NSArray : ExpressibleByArrayLiteral {
  /// Create an instance initialized with `elements`.
  public required convenience init(arrayLiteral elements: Any...) {
    // Let bridging take care of it.
    self.init(array: elements)
  }
}

extension NSArray {
  /// Initializes a newly allocated array by placing in it the objects
  /// contained in a given array.
  ///
  /// - Returns: An array initialized to contain the objects in
  ///    `anArray``. The returned object might be different than the
  ///    original receiver.
  ///
  /// Discussion: After an immutable array has been initialized in
  /// this way, it cannot be modified.
  @nonobjc
  public convenience init(array anArray: __shared NSArray) {
    self.init(array: anArray as Array)
  }
}

extension NSArray : CustomReflectable {
  public var customMirror: Mirror {
    return Mirror(reflecting: self as [AnyObject])
  }
}


