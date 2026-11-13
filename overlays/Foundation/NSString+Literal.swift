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

// From release/5.4 stdlib/public/Darwin/Foundation/NSString.swift: NSString string literals and appendingFormat,
// with Darling's import names.

@_exported import Foundation // Clang module

extension NSString : ExpressibleByStringLiteral {
  /// Create an instance initialized to `value`.
  public required convenience init(stringLiteral value: StaticString) {
    var immutableResult: NSString
    if value.hasPointerRepresentation {
      immutableResult = NSString(
        bytesNoCopy: UnsafeMutableRawPointer(mutating: value.utf8Start),
        length: Int(value.utf8CodeUnitCount),
        encoding: value.isASCII ? String.Encoding.ascii.rawValue : String.Encoding.utf8.rawValue,
        freeWhenDone: false)!
    } else {
      var uintValue = value.unicodeScalar
      immutableResult = NSString(
        bytes: &uintValue,
        length: 4,
        encoding: String.Encoding.utf32.rawValue)!
    }
    self.init(string: immutableResult as String)
  }
}

extension NSString {
  public func appendingFormat(_ format: NSString, _ args: CVarArg...)
  -> NSString {
    return withVaList(args) {
      self.appending(NSString(format: format as String, arguments: $0) as String) as NSString
    }
  }
}
