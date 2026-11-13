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

// From release/5.4 (apple/swift 845205b4407c) stdlib/public/Darwin/Foundation/NSError.swift: ErrorUserInfoKey.

@_exported import Foundation // Clang module

public struct ErrorUserInfoKey : RawRepresentable, _SwiftNewtypeWrapper, Equatable, Hashable, _ObjectiveCBridgeable {
  public typealias _ObjectiveCType = NSString
  public init(rawValue: String) { self.rawValue = rawValue }
  public var rawValue: String
}

public extension ErrorUserInfoKey {
  @available(*, deprecated, renamed: "NSUnderlyingErrorKey")
  static let underlyingErrorKey = ErrorUserInfoKey(rawValue: NSUnderlyingErrorKey)

  @available(*, deprecated, renamed: "NSLocalizedDescriptionKey")
  static let localizedDescriptionKey = ErrorUserInfoKey(rawValue: NSLocalizedDescriptionKey)

  @available(*, deprecated, renamed: "NSLocalizedFailureReasonErrorKey")
  static let localizedFailureReasonErrorKey = ErrorUserInfoKey(rawValue: NSLocalizedFailureReasonErrorKey)

  @available(*, deprecated, renamed: "NSLocalizedRecoverySuggestionErrorKey")
  static let localizedRecoverySuggestionErrorKey = ErrorUserInfoKey(rawValue: NSLocalizedRecoverySuggestionErrorKey)

  @available(*, deprecated, renamed: "NSLocalizedRecoveryOptionsErrorKey")
  static let localizedRecoveryOptionsErrorKey = ErrorUserInfoKey(rawValue: NSLocalizedRecoveryOptionsErrorKey)

  @available(*, deprecated, renamed: "NSRecoveryAttempterErrorKey")
  static let recoveryAttempterErrorKey = ErrorUserInfoKey(rawValue: NSRecoveryAttempterErrorKey)

  @available(*, deprecated, renamed: "NSHelpAnchorErrorKey")
  static let helpAnchorErrorKey = ErrorUserInfoKey(rawValue: NSHelpAnchorErrorKey)

  @available(*, deprecated, renamed: "NSStringEncodingErrorKey")
  static let stringEncodingErrorKey = ErrorUserInfoKey(rawValue: NSStringEncodingErrorKey)

  @available(*, deprecated, renamed: "NSURLErrorKey")
  static let NSURLErrorKey = ErrorUserInfoKey(rawValue: Foundation.NSURLErrorKey)

  @available(*, deprecated, renamed: "NSFilePathErrorKey")
  static let filePathErrorKey = ErrorUserInfoKey(rawValue: NSFilePathErrorKey)
}
