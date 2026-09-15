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

// From release/5.4 stdlib/public/Darwin/Foundation/NSDictionary.swift (the dictionary literal conformance). Darling
// imports -initWithObjects:forKeys:count: with optional element pointers.

@_exported import Foundation // Clang module

private func duckCastToNSCopying(_ x: Any) -> NSCopying {
  return _unsafeReferenceCast(x as AnyObject, to: NSCopying.self)
}

extension NSDictionary : ExpressibleByDictionaryLiteral {
  public required convenience init(
    dictionaryLiteral elements: (Any, Any)...
  ) {
    let objects: [AnyObject?] = elements.map { $0.1 as AnyObject }
    let keys: [NSCopying?] = elements.map { duckCastToNSCopying($0.0) }
    self.init(objects: objects, forKeys: keys, count: elements.count)
  }
}
