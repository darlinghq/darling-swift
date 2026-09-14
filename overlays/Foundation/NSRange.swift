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

// Range <-> NSRange conversions, from release/5.4 stdlib/public/Darwin/Foundation/NSRange.swift.
// Darling: NSRange's lowerBound/upperBound helpers aren't included, so location/length are used directly.

@_exported import Foundation // Clang module

extension Range where Bound: BinaryInteger {
  public init?(_ range: NSRange) {
    guard range.location != NSNotFound else { return nil }
    self.init(uncheckedBounds: (numericCast(range.location), numericCast(range.location + range.length)))
  }
}

// This additional overload will mean Range.init(_:) defaults to Range<Int> when
// no additional type context is provided:
extension Range where Bound == Int {
  public init?(_ range: NSRange) {
    guard range.location != NSNotFound else { return nil }
    self.init(uncheckedBounds: (range.location, range.location + range.length))
  }
}

extension Range where Bound == String.Index {
  private init?<S: StringProtocol>(
    _ range: NSRange, _genericIn string: __shared S
  ) {
    let u = string.utf16
    guard range.location != NSNotFound,
      let start = u.index(
        u.startIndex, offsetBy: range.location, limitedBy: u.endIndex),
      let end = u.index(
        start, offsetBy: range.length, limitedBy: u.endIndex),
      let lowerBound = String.Index(start, within: string),
      let upperBound = String.Index(end, within: string)
    else { return nil }

    self = lowerBound..<upperBound
  }

  public init?(_ range: NSRange, in string: __shared String) {
    self.init(range, _genericIn: string)
  }

  public init?<S: StringProtocol>(_ range: NSRange, in string: __shared S) {
    self.init(range, _genericIn: string)
  }
}
