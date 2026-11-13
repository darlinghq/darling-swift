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

// From release/5.4 stdlib/public/Darwin/Foundation/NSError.swift: CocoaError and its Code, with only the codes apps
// import (the full code table is left out).

@_exported import Foundation // Clang module

public typealias NSCocoaError = CocoaError

/// Describes errors within the Cocoa error domain.
public struct CocoaError : _BridgedStoredNSError {
  public let _nsError: NSError

  public init(_nsError error: NSError) {
    precondition(error.domain() == NSCocoaErrorDomain)
    self._nsError = error
  }

  public static var errorDomain: String { return NSCocoaErrorDomain }

  public var hashValue: Int {
    return _nsError.hashValue
  }

  /// The error code itself.
  public struct Code : RawRepresentable, Hashable, _ErrorCodeProtocol {
    public typealias _ErrorType = CocoaError

    public let rawValue: Int

    public init(rawValue: Int) {
      self.rawValue = rawValue
    }
  }
}

extension CocoaError.Code {
  @available(macOS, introduced: 10.7) @available(iOS, introduced: 5.0)
  public static var fileWriteFileExists: CocoaError.Code {
    return CocoaError.Code(rawValue: 516)
  }
}

extension CocoaError {
  @available(macOS, introduced: 10.7) @available(iOS, introduced: 5.0)
  public static var fileWriteFileExists: CocoaError.Code {
    return CocoaError.Code(rawValue: 516)
  }
}
