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

// From release/5.4 (apple/swift 845205b4407c) stdlib/public/Darwin/Foundation/NSError.swift, CocoaError and its error codes.

@_exported import Foundation // Clang module
import CoreFoundation

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

public extension CocoaError {
  private var _nsUserInfo: [AnyHashable : Any] {
    return (self as NSError).userInfo() ?? [:]
  }

  /// The file path associated with the error, if any.
  var filePath: String? {
    return _nsUserInfo[NSFilePathErrorKey as NSString] as? String
  }

  /// The string encoding associated with this error, if any.
  var stringEncoding: String.Encoding? {
    return (_nsUserInfo[NSStringEncodingErrorKey as NSString] as? NSNumber)
             .map { String.Encoding(rawValue: $0.unsignedIntegerValue()) }
  }

  /// The underlying error behind this error, if any.
  var underlying: Error? {
    return _nsUserInfo[NSUnderlyingErrorKey as NSString] as? Error
  }

  /// The URL associated with this error, if any.
  var url: URL? {
    return _nsUserInfo[NSURLErrorKey as NSString] as? URL
  }
}

extension CocoaError {
    public static func error(_ code: CocoaError.Code, userInfo: [AnyHashable : Any]? = nil, url: URL? = nil) -> Error {
        var info: [String : Any] = userInfo as? [String : Any] ?? [:]
        if let url = url {
            info[NSURLErrorKey] = url
        }
        return NSError(domain: NSCocoaErrorDomain, code: code.rawValue, userInfo: info)
    }
}

extension CocoaError.Code {
  public static var fileNoSuchFile: CocoaError.Code {
    return CocoaError.Code(rawValue: 4)
  }
  public static var fileLocking: CocoaError.Code {
    return CocoaError.Code(rawValue: 255)
  }
  public static var fileReadUnknown: CocoaError.Code {
    return CocoaError.Code(rawValue: 256)
  }
  public static var fileReadNoPermission: CocoaError.Code {
    return CocoaError.Code(rawValue: 257)
  }
  public static var fileReadInvalidFileName: CocoaError.Code {
    return CocoaError.Code(rawValue: 258)
  }
  public static var fileReadCorruptFile: CocoaError.Code {
    return CocoaError.Code(rawValue: 259)
  }
  public static var fileReadNoSuchFile: CocoaError.Code {
    return CocoaError.Code(rawValue: 260)
  }
  public static var fileReadInapplicableStringEncoding: CocoaError.Code {
    return CocoaError.Code(rawValue: 261)
  }
  public static var fileReadUnsupportedScheme: CocoaError.Code {
    return CocoaError.Code(rawValue: 262)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  public static var fileReadTooLarge: CocoaError.Code {
    return CocoaError.Code(rawValue: 263)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  public static var fileReadUnknownStringEncoding: CocoaError.Code {
    return CocoaError.Code(rawValue: 264)
  }

  public static var fileWriteUnknown: CocoaError.Code {
    return CocoaError.Code(rawValue: 512)
  }
  public static var fileWriteNoPermission: CocoaError.Code {
    return CocoaError.Code(rawValue: 513)
  }
  public static var fileWriteInvalidFileName: CocoaError.Code {
    return CocoaError.Code(rawValue: 514)
  }

  @available(macOS, introduced: 10.7) @available(iOS, introduced: 5.0)
  public static var fileWriteFileExists: CocoaError.Code {
    return CocoaError.Code(rawValue: 516)
  }

  public static var fileWriteInapplicableStringEncoding: CocoaError.Code {
    return CocoaError.Code(rawValue: 517)
  }
  public static var fileWriteUnsupportedScheme: CocoaError.Code {
    return CocoaError.Code(rawValue: 518)
  }
  public static var fileWriteOutOfSpace: CocoaError.Code {
    return CocoaError.Code(rawValue: 640)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  public static var fileWriteVolumeReadOnly: CocoaError.Code {
    return CocoaError.Code(rawValue: 642)
  }

  @available(macOS, introduced: 10.11) @available(iOS, unavailable)
  public static var fileManagerUnmountUnknown: CocoaError.Code {
    return CocoaError.Code(rawValue: 768)
  }

  @available(macOS, introduced: 10.11) @available(iOS, unavailable)
  public static var fileManagerUnmountBusy: CocoaError.Code {
    return CocoaError.Code(rawValue: 769)
  }

  public static var keyValueValidation: CocoaError.Code {
    return CocoaError.Code(rawValue: 1024)
  }
  public static var formatting: CocoaError.Code {
    return CocoaError.Code(rawValue: 2048)
  }
  public static var userCancelled: CocoaError.Code {
    return CocoaError.Code(rawValue: 3072)
  }

  @available(macOS, introduced: 10.8) @available(iOS, introduced: 6.0)
  public static var featureUnsupported: CocoaError.Code {
    return CocoaError.Code(rawValue: 3328)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  public static var executableNotLoadable: CocoaError.Code {
    return CocoaError.Code(rawValue: 3584)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  public static var executableArchitectureMismatch: CocoaError.Code {
    return CocoaError.Code(rawValue: 3585)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  public static var executableRuntimeMismatch: CocoaError.Code {
    return CocoaError.Code(rawValue: 3586)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  public static var executableLoad: CocoaError.Code {
    return CocoaError.Code(rawValue: 3587)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  public static var executableLink: CocoaError.Code {
    return CocoaError.Code(rawValue: 3588)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  public static var propertyListReadCorrupt: CocoaError.Code {
    return CocoaError.Code(rawValue: 3840)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  public static var propertyListReadUnknownVersion: CocoaError.Code {
    return CocoaError.Code(rawValue: 3841)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  public static var propertyListReadStream: CocoaError.Code {
    return CocoaError.Code(rawValue: 3842)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  public static var propertyListWriteStream: CocoaError.Code {
    return CocoaError.Code(rawValue: 3851)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  public static var propertyListWriteInvalid: CocoaError.Code {
    return CocoaError.Code(rawValue: 3852)
  }

  @available(macOS, introduced: 10.8) @available(iOS, introduced: 6.0)
  public static var xpcConnectionInterrupted: CocoaError.Code {
    return CocoaError.Code(rawValue: 4097)
  }

  @available(macOS, introduced: 10.8) @available(iOS, introduced: 6.0)
  public static var xpcConnectionInvalid: CocoaError.Code {
    return CocoaError.Code(rawValue: 4099)
  }

  @available(macOS, introduced: 10.8) @available(iOS, introduced: 6.0)
  public static var xpcConnectionReplyInvalid: CocoaError.Code {
    return CocoaError.Code(rawValue: 4101)
  }

  @available(macOS, introduced: 10.9) @available(iOS, introduced: 7.0)
  public static var ubiquitousFileUnavailable: CocoaError.Code {
    return CocoaError.Code(rawValue: 4353)
  }

  @available(macOS, introduced: 10.9) @available(iOS, introduced: 7.0)
  public static var ubiquitousFileNotUploadedDueToQuota: CocoaError.Code {
    return CocoaError.Code(rawValue: 4354)
  }

  @available(macOS, introduced: 10.9) @available(iOS, introduced: 7.0)
  public static var ubiquitousFileUbiquityServerNotAvailable: CocoaError.Code {
    return CocoaError.Code(rawValue: 4355)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  public static var userActivityHandoffFailed: CocoaError.Code {
    return CocoaError.Code(rawValue: 4608)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  public static var userActivityConnectionUnavailable: CocoaError.Code {
    return CocoaError.Code(rawValue: 4609)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  public static var userActivityRemoteApplicationTimedOut: CocoaError.Code {
    return CocoaError.Code(rawValue: 4610)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  public static var userActivityHandoffUserInfoTooLarge: CocoaError.Code {
    return CocoaError.Code(rawValue: 4611)
  }

  @available(macOS, introduced: 10.11) @available(iOS, introduced: 9.0)
  public static var coderReadCorrupt: CocoaError.Code {
    return CocoaError.Code(rawValue: 4864)
  }

  @available(macOS, introduced: 10.11) @available(iOS, introduced: 9.0)
  public static var coderValueNotFound: CocoaError.Code {
    return CocoaError.Code(rawValue: 4865)
  }

  public static var coderInvalidValue: CocoaError.Code {
    return CocoaError.Code(rawValue: 4866)
  }
}

extension CocoaError.Code {
  @available(*, deprecated, renamed: "fileNoSuchFile")
  public static var fileNoSuchFileError: CocoaError.Code {
    return CocoaError.Code(rawValue: 4)
  }
  @available(*, deprecated, renamed: "fileLocking")
  public static var fileLockingError: CocoaError.Code {
    return CocoaError.Code(rawValue: 255)
  }
  @available(*, deprecated, renamed: "fileReadUnknown")
  public static var fileReadUnknownError: CocoaError.Code {
    return CocoaError.Code(rawValue: 256)
  }
  @available(*, deprecated, renamed: "fileReadNoPermission")
  public static var fileReadNoPermissionError: CocoaError.Code {
    return CocoaError.Code(rawValue: 257)
  }
  @available(*, deprecated, renamed: "fileReadInvalidFileName")
  public static var fileReadInvalidFileNameError: CocoaError.Code {
    return CocoaError.Code(rawValue: 258)
  }
  @available(*, deprecated, renamed: "fileReadCorruptFile")
  public static var fileReadCorruptFileError: CocoaError.Code {
    return CocoaError.Code(rawValue: 259)
  }
  @available(*, deprecated, renamed: "fileReadNoSuchFile")
  public static var fileReadNoSuchFileError: CocoaError.Code {
    return CocoaError.Code(rawValue: 260)
  }
  @available(*, deprecated, renamed: "fileReadInapplicableStringEncoding")
  public static var fileReadInapplicableStringEncodingError: CocoaError.Code {
    return CocoaError.Code(rawValue: 261)
  }
  @available(*, deprecated, renamed: "fileReadUnsupportedScheme")
  public static var fileReadUnsupportedSchemeError: CocoaError.Code {
    return CocoaError.Code(rawValue: 262)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  @available(*, deprecated, renamed: "fileReadTooLarge")
  public static var fileReadTooLargeError: CocoaError.Code {
    return CocoaError.Code(rawValue: 263)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  @available(*, deprecated, renamed: "fileReadUnknownStringEncoding")
  public static var fileReadUnknownStringEncodingError: CocoaError.Code {
    return CocoaError.Code(rawValue: 264)
  }

  @available(*, deprecated, renamed: "fileWriteUnknown")
  public static var fileWriteUnknownError: CocoaError.Code {
    return CocoaError.Code(rawValue: 512)
  }

  @available(*, deprecated, renamed: "fileWriteNoPermission")
  public static var fileWriteNoPermissionError: CocoaError.Code {
    return CocoaError.Code(rawValue: 513)
  }

  @available(*, deprecated, renamed: "fileWriteInvalidFileName")
  public static var fileWriteInvalidFileNameError: CocoaError.Code {
    return CocoaError.Code(rawValue: 514)
  }

  @available(macOS, introduced: 10.7) @available(iOS, introduced: 5.0)
  @available(*, deprecated, renamed: "fileWriteFileExists")
  public static var fileWriteFileExistsError: CocoaError.Code {
    return CocoaError.Code(rawValue: 516)
  }

  @available(*, deprecated, renamed: "fileWriteInapplicableStringEncoding")
  public static var fileWriteInapplicableStringEncodingError: CocoaError.Code {
    return CocoaError.Code(rawValue: 517)
  }

  @available(*, deprecated, renamed: "fileWriteUnsupportedScheme")
  public static var fileWriteUnsupportedSchemeError: CocoaError.Code {
    return CocoaError.Code(rawValue: 518)
  }

  @available(*, deprecated, renamed: "fileWriteOutOfSpace")
  public static var fileWriteOutOfSpaceError: CocoaError.Code {
    return CocoaError.Code(rawValue: 640)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  @available(*, deprecated, renamed: "fileWriteVolumeReadOnly")
  public static var fileWriteVolumeReadOnlyError: CocoaError.Code {
    return CocoaError.Code(rawValue: 642)
  }

  @available(macOS, introduced: 10.11) @available(iOS, unavailable)
  @available(*, deprecated, renamed: "fileManagerUnmountUnknown")
  public static var fileManagerUnmountUnknownError: CocoaError.Code {
    return CocoaError.Code(rawValue: 768)
  }

  @available(macOS, introduced: 10.11) @available(iOS, unavailable)
  @available(*, deprecated, renamed: "fileManagerUnmountBusy")
  public static var fileManagerUnmountBusyError: CocoaError.Code {
    return CocoaError.Code(rawValue: 769)
  }

  @available(*, deprecated, renamed: "keyValueValidation")
  public static var keyValueValidationError: CocoaError.Code {
    return CocoaError.Code(rawValue: 1024)
  }

  @available(*, deprecated, renamed: "formatting")
  public static var formattingError: CocoaError.Code {
    return CocoaError.Code(rawValue: 2048)
  }

  @available(*, deprecated, renamed: "userCancelled")
  public static var userCancelledError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3072)
  }

  @available(macOS, introduced: 10.8) @available(iOS, introduced: 6.0)
  @available(*, deprecated, renamed: "featureUnsupported")
  public static var featureUnsupportedError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3328)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  @available(*, deprecated, renamed: "executableNotLoadable")
  public static var executableNotLoadableError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3584)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  @available(*, deprecated, renamed: "executableArchitectureMismatch")
  public static var executableArchitectureMismatchError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3585)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  @available(*, deprecated, renamed: "executableRuntimeMismatch")
  public static var executableRuntimeMismatchError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3586)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  @available(*, deprecated, renamed: "executableLoad")
  public static var executableLoadError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3587)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  @available(*, deprecated, renamed: "executableLink")
  public static var executableLinkError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3588)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  @available(*, deprecated, renamed: "propertyListReadCorrupt")
  public static var propertyListReadCorruptError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3840)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  @available(*, deprecated, renamed: "propertyListReadUnknownVersion")
  public static var propertyListReadUnknownVersionError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3841)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  @available(*, deprecated, renamed: "propertyListReadStream")
  public static var propertyListReadStreamError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3842)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  @available(*, deprecated, renamed: "propertyListWriteStream")
  public static var propertyListWriteStreamError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3851)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  @available(*, deprecated, renamed: "propertyListWriteInvalid")
  public static var propertyListWriteInvalidError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3852)
  }

  @available(macOS, introduced: 10.9) @available(iOS, introduced: 7.0)
  @available(*, deprecated, renamed: "ubiquitousFileUnavailable")
  public static var ubiquitousFileUnavailableError: CocoaError.Code {
    return CocoaError.Code(rawValue: 4353)
  }

  @available(macOS, introduced: 10.9) @available(iOS, introduced: 7.0)
  @available(*, deprecated, renamed: "ubiquitousFileNotUploadedDueToQuota")
  public static var ubiquitousFileNotUploadedDueToQuotaError: CocoaError.Code {
    return CocoaError.Code(rawValue: 4354)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  @available(*, deprecated, renamed: "userActivityHandoffFailed")
  public static var userActivityHandoffFailedError: CocoaError.Code {
    return CocoaError.Code(rawValue: 4608)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  @available(*, deprecated, renamed: "userActivityConnectionUnavailable")
  public static var userActivityConnectionUnavailableError: CocoaError.Code {
    return CocoaError.Code(rawValue: 4609)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  @available(*, deprecated, renamed: "userActivityRemoteApplicationTimedOut")
  public static var userActivityRemoteApplicationTimedOutError: CocoaError.Code {
    return CocoaError.Code(rawValue: 4610)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  @available(*, deprecated, renamed: "userActivityHandoffUserInfoTooLarge")
  public static var userActivityHandoffUserInfoTooLargeError: CocoaError.Code {
    return CocoaError.Code(rawValue: 4611)
  }

  @available(macOS, introduced: 10.11) @available(iOS, introduced: 9.0)
  @available(*, deprecated, renamed: "coderReadCorrupt")
  public static var coderReadCorruptError: CocoaError.Code {
    return CocoaError.Code(rawValue: 4864)
  }

  @available(macOS, introduced: 10.11) @available(iOS, introduced: 9.0)
  @available(*, deprecated, renamed: "coderValueNotFound")
  public static var coderValueNotFoundError: CocoaError.Code {
    return CocoaError.Code(rawValue: 4865)
  }
}

extension CocoaError {
  public static var fileNoSuchFile: CocoaError.Code {
    return CocoaError.Code(rawValue: 4)
  }
  public static var fileLocking: CocoaError.Code {
    return CocoaError.Code(rawValue: 255)
  }
  public static var fileReadUnknown: CocoaError.Code {
    return CocoaError.Code(rawValue: 256)
  }
  public static var fileReadNoPermission: CocoaError.Code {
    return CocoaError.Code(rawValue: 257)
  }
  public static var fileReadInvalidFileName: CocoaError.Code {
    return CocoaError.Code(rawValue: 258)
  }
  public static var fileReadCorruptFile: CocoaError.Code {
    return CocoaError.Code(rawValue: 259)
  }
  public static var fileReadNoSuchFile: CocoaError.Code {
    return CocoaError.Code(rawValue: 260)
  }
  public static var fileReadInapplicableStringEncoding: CocoaError.Code {
    return CocoaError.Code(rawValue: 261)
  }
  public static var fileReadUnsupportedScheme: CocoaError.Code {
    return CocoaError.Code(rawValue: 262)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  public static var fileReadTooLarge: CocoaError.Code {
    return CocoaError.Code(rawValue: 263)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  public static var fileReadUnknownStringEncoding: CocoaError.Code {
    return CocoaError.Code(rawValue: 264)
  }

  public static var fileWriteUnknown: CocoaError.Code {
    return CocoaError.Code(rawValue: 512)
  }
  public static var fileWriteNoPermission: CocoaError.Code {
    return CocoaError.Code(rawValue: 513)
  }
  public static var fileWriteInvalidFileName: CocoaError.Code {
    return CocoaError.Code(rawValue: 514)
  }

  @available(macOS, introduced: 10.7) @available(iOS, introduced: 5.0)
  public static var fileWriteFileExists: CocoaError.Code {
    return CocoaError.Code(rawValue: 516)
  }

  public static var fileWriteInapplicableStringEncoding: CocoaError.Code {
    return CocoaError.Code(rawValue: 517)
  }
  public static var fileWriteUnsupportedScheme: CocoaError.Code {
    return CocoaError.Code(rawValue: 518)
  }
  public static var fileWriteOutOfSpace: CocoaError.Code {
    return CocoaError.Code(rawValue: 640)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  public static var fileWriteVolumeReadOnly: CocoaError.Code {
    return CocoaError.Code(rawValue: 642)
  }

  @available(macOS, introduced: 10.11) @available(iOS, unavailable)
  public static var fileManagerUnmountUnknown: CocoaError.Code {
    return CocoaError.Code(rawValue: 768)
  }

  @available(macOS, introduced: 10.11) @available(iOS, unavailable)
  public static var fileManagerUnmountBusy: CocoaError.Code {
    return CocoaError.Code(rawValue: 769)
  }

  public static var keyValueValidation: CocoaError.Code {
    return CocoaError.Code(rawValue: 1024)
  }
  public static var formatting: CocoaError.Code {
    return CocoaError.Code(rawValue: 2048)
  }
  public static var userCancelled: CocoaError.Code {
    return CocoaError.Code(rawValue: 3072)
  }

  @available(macOS, introduced: 10.8) @available(iOS, introduced: 6.0)
  public static var featureUnsupported: CocoaError.Code {
    return CocoaError.Code(rawValue: 3328)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  public static var executableNotLoadable: CocoaError.Code {
    return CocoaError.Code(rawValue: 3584)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  public static var executableArchitectureMismatch: CocoaError.Code {
    return CocoaError.Code(rawValue: 3585)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  public static var executableRuntimeMismatch: CocoaError.Code {
    return CocoaError.Code(rawValue: 3586)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  public static var executableLoad: CocoaError.Code {
    return CocoaError.Code(rawValue: 3587)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  public static var executableLink: CocoaError.Code {
    return CocoaError.Code(rawValue: 3588)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  public static var propertyListReadCorrupt: CocoaError.Code {
    return CocoaError.Code(rawValue: 3840)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  public static var propertyListReadUnknownVersion: CocoaError.Code {
    return CocoaError.Code(rawValue: 3841)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  public static var propertyListReadStream: CocoaError.Code {
    return CocoaError.Code(rawValue: 3842)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  public static var propertyListWriteStream: CocoaError.Code {
    return CocoaError.Code(rawValue: 3851)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  public static var propertyListWriteInvalid: CocoaError.Code {
    return CocoaError.Code(rawValue: 3852)
  }

  @available(macOS, introduced: 10.8) @available(iOS, introduced: 6.0)
  public static var xpcConnectionInterrupted: CocoaError.Code {
    return CocoaError.Code(rawValue: 4097)
  }

  @available(macOS, introduced: 10.8) @available(iOS, introduced: 6.0)
  public static var xpcConnectionInvalid: CocoaError.Code {
    return CocoaError.Code(rawValue: 4099)
  }

  @available(macOS, introduced: 10.8) @available(iOS, introduced: 6.0)
  public static var xpcConnectionReplyInvalid: CocoaError.Code {
    return CocoaError.Code(rawValue: 4101)
  }

  @available(macOS, introduced: 10.9) @available(iOS, introduced: 7.0)
  public static var ubiquitousFileUnavailable: CocoaError.Code {
    return CocoaError.Code(rawValue: 4353)
  }

  @available(macOS, introduced: 10.9) @available(iOS, introduced: 7.0)
  public static var ubiquitousFileNotUploadedDueToQuota: CocoaError.Code {
    return CocoaError.Code(rawValue: 4354)
  }

  @available(macOS, introduced: 10.9) @available(iOS, introduced: 7.0)
  public static var ubiquitousFileUbiquityServerNotAvailable: CocoaError.Code {
    return CocoaError.Code(rawValue: 4355)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  public static var userActivityHandoffFailed: CocoaError.Code {
    return CocoaError.Code(rawValue: 4608)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  public static var userActivityConnectionUnavailable: CocoaError.Code {
    return CocoaError.Code(rawValue: 4609)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  public static var userActivityRemoteApplicationTimedOut: CocoaError.Code {
    return CocoaError.Code(rawValue: 4610)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  public static var userActivityHandoffUserInfoTooLarge: CocoaError.Code {
    return CocoaError.Code(rawValue: 4611)
  }

  @available(macOS, introduced: 10.11) @available(iOS, introduced: 9.0)
  public static var coderReadCorrupt: CocoaError.Code {
    return CocoaError.Code(rawValue: 4864)
  }

  @available(macOS, introduced: 10.11) @available(iOS, introduced: 9.0)
  public static var coderValueNotFound: CocoaError.Code {
    return CocoaError.Code(rawValue: 4865)
  }

  public static var coderInvalidValue: CocoaError.Code {
    return CocoaError.Code(rawValue: 4866)
  }
}

extension CocoaError {
  @available(*, deprecated, renamed: "fileNoSuchFile")
  public static var fileNoSuchFileError: CocoaError.Code {
    return CocoaError.Code(rawValue: 4)
  }
  @available(*, deprecated, renamed: "fileLocking")
  public static var fileLockingError: CocoaError.Code {
    return CocoaError.Code(rawValue: 255)
  }
  @available(*, deprecated, renamed: "fileReadUnknown")
  public static var fileReadUnknownError: CocoaError.Code {
    return CocoaError.Code(rawValue: 256)
  }
  @available(*, deprecated, renamed: "fileReadNoPermission")
  public static var fileReadNoPermissionError: CocoaError.Code {
    return CocoaError.Code(rawValue: 257)
  }
  @available(*, deprecated, renamed: "fileReadInvalidFileName")
  public static var fileReadInvalidFileNameError: CocoaError.Code {
    return CocoaError.Code(rawValue: 258)
  }
  @available(*, deprecated, renamed: "fileReadCorruptFile")
  public static var fileReadCorruptFileError: CocoaError.Code {
    return CocoaError.Code(rawValue: 259)
  }
  @available(*, deprecated, renamed: "fileReadNoSuchFile")
  public static var fileReadNoSuchFileError: CocoaError.Code {
    return CocoaError.Code(rawValue: 260)
  }
  @available(*, deprecated, renamed: "fileReadInapplicableStringEncoding")
  public static var fileReadInapplicableStringEncodingError: CocoaError.Code {
    return CocoaError.Code(rawValue: 261)
  }
  @available(*, deprecated, renamed: "fileReadUnsupportedScheme")
  public static var fileReadUnsupportedSchemeError: CocoaError.Code {
    return CocoaError.Code(rawValue: 262)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  @available(*, deprecated, renamed: "fileReadTooLarge")
  public static var fileReadTooLargeError: CocoaError.Code {
    return CocoaError.Code(rawValue: 263)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  @available(*, deprecated, renamed: "fileReadUnknownStringEncoding")
  public static var fileReadUnknownStringEncodingError: CocoaError.Code {
    return CocoaError.Code(rawValue: 264)
  }

  @available(*, deprecated, renamed: "fileWriteUnknown")
  public static var fileWriteUnknownError: CocoaError.Code {
    return CocoaError.Code(rawValue: 512)
  }

  @available(*, deprecated, renamed: "fileWriteNoPermission")
  public static var fileWriteNoPermissionError: CocoaError.Code {
    return CocoaError.Code(rawValue: 513)
  }

  @available(*, deprecated, renamed: "fileWriteInvalidFileName")
  public static var fileWriteInvalidFileNameError: CocoaError.Code {
    return CocoaError.Code(rawValue: 514)
  }

  @available(macOS, introduced: 10.7) @available(iOS, introduced: 5.0)
  @available(*, deprecated, renamed: "fileWriteFileExists")
  public static var fileWriteFileExistsError: CocoaError.Code {
    return CocoaError.Code(rawValue: 516)
  }

  @available(*, deprecated, renamed: "fileWriteInapplicableStringEncoding")
  public static var fileWriteInapplicableStringEncodingError: CocoaError.Code {
    return CocoaError.Code(rawValue: 517)
  }

  @available(*, deprecated, renamed: "fileWriteUnsupportedScheme")
  public static var fileWriteUnsupportedSchemeError: CocoaError.Code {
    return CocoaError.Code(rawValue: 518)
  }

  @available(*, deprecated, renamed: "fileWriteOutOfSpace")
  public static var fileWriteOutOfSpaceError: CocoaError.Code {
    return CocoaError.Code(rawValue: 640)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  @available(*, deprecated, renamed: "fileWriteVolumeReadOnly")
  public static var fileWriteVolumeReadOnlyError: CocoaError.Code {
    return CocoaError.Code(rawValue: 642)
  }

  @available(macOS, introduced: 10.11) @available(iOS, unavailable)
  @available(*, deprecated, renamed: "fileManagerUnmountUnknown")
  public static var fileManagerUnmountUnknownError: CocoaError.Code {
    return CocoaError.Code(rawValue: 768)
  }

  @available(macOS, introduced: 10.11) @available(iOS, unavailable)
  @available(*, deprecated, renamed: "fileManagerUnmountBusy")
  public static var fileManagerUnmountBusyError: CocoaError.Code {
    return CocoaError.Code(rawValue: 769)
  }

  @available(*, deprecated, renamed: "keyValueValidation")
  public static var keyValueValidationError: CocoaError.Code {
    return CocoaError.Code(rawValue: 1024)
  }

  @available(*, deprecated, renamed: "formatting")
  public static var formattingError: CocoaError.Code {
    return CocoaError.Code(rawValue: 2048)
  }

  @available(*, deprecated, renamed: "userCancelled")
  public static var userCancelledError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3072)
  }

  @available(macOS, introduced: 10.8) @available(iOS, introduced: 6.0)
  @available(*, deprecated, renamed: "featureUnsupported")
  public static var featureUnsupportedError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3328)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  @available(*, deprecated, renamed: "executableNotLoadable")
  public static var executableNotLoadableError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3584)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  @available(*, deprecated, renamed: "executableArchitectureMismatch")
  public static var executableArchitectureMismatchError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3585)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  @available(*, deprecated, renamed: "executableRuntimeMismatch")
  public static var executableRuntimeMismatchError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3586)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  @available(*, deprecated, renamed: "executableLoad")
  public static var executableLoadError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3587)
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  @available(*, deprecated, renamed: "executableLink")
  public static var executableLinkError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3588)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  @available(*, deprecated, renamed: "propertyListReadCorrupt")
  public static var propertyListReadCorruptError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3840)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  @available(*, deprecated, renamed: "propertyListReadUnknownVersion")
  public static var propertyListReadUnknownVersionError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3841)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  @available(*, deprecated, renamed: "propertyListReadStream")
  public static var propertyListReadStreamError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3842)
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  @available(*, deprecated, renamed: "propertyListWriteStream")
  public static var propertyListWriteStreamError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3851)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  @available(*, deprecated, renamed: "propertyListWriteInvalid")
  public static var propertyListWriteInvalidError: CocoaError.Code {
    return CocoaError.Code(rawValue: 3852)
  }

  @available(macOS, introduced: 10.9) @available(iOS, introduced: 7.0)
  @available(*, deprecated, renamed: "ubiquitousFileUnavailable")
  public static var ubiquitousFileUnavailableError: CocoaError.Code {
    return CocoaError.Code(rawValue: 4353)
  }

  @available(macOS, introduced: 10.9) @available(iOS, introduced: 7.0)
  @available(*, deprecated, renamed: "ubiquitousFileNotUploadedDueToQuota")
  public static var ubiquitousFileNotUploadedDueToQuotaError: CocoaError.Code {
    return CocoaError.Code(rawValue: 4354)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  @available(*, deprecated, renamed: "userActivityHandoffFailed")
  public static var userActivityHandoffFailedError: CocoaError.Code {
    return CocoaError.Code(rawValue: 4608)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  @available(*, deprecated, renamed: "userActivityConnectionUnavailable")
  public static var userActivityConnectionUnavailableError: CocoaError.Code {
    return CocoaError.Code(rawValue: 4609)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  @available(*, deprecated, renamed: "userActivityRemoteApplicationTimedOut")
  public static var userActivityRemoteApplicationTimedOutError: CocoaError.Code {
    return CocoaError.Code(rawValue: 4610)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  @available(*, deprecated, renamed: "userActivityHandoffUserInfoTooLarge")
  public static var userActivityHandoffUserInfoTooLargeError: CocoaError.Code {
    return CocoaError.Code(rawValue: 4611)
  }

  @available(macOS, introduced: 10.11) @available(iOS, introduced: 9.0)
  @available(*, deprecated, renamed: "coderReadCorrupt")
  public static var coderReadCorruptError: CocoaError.Code {
    return CocoaError.Code(rawValue: 4864)
  }

  @available(macOS, introduced: 10.11) @available(iOS, introduced: 9.0)
  @available(*, deprecated, renamed: "coderValueNotFound")
  public static var coderValueNotFoundError: CocoaError.Code {
    return CocoaError.Code(rawValue: 4865)
  }
}

extension CocoaError {
  @available(macOS, introduced: 10.11) @available(iOS, introduced: 9.0)
  public var isCoderError: Bool {
    return code.rawValue >= 4864 && code.rawValue <= 4991
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  public var isExecutableError: Bool {
    return code.rawValue >= 3584 && code.rawValue <= 3839
  }

  public var isFileError: Bool {
    return code.rawValue >= 0 && code.rawValue <= 1023
  }

  public var isFormattingError: Bool {
    return code.rawValue >= 2048 && code.rawValue <= 2559
  }

  @available(macOS, introduced: 10.6) @available(iOS, introduced: 4.0)
  public var isPropertyListError: Bool {
    return code.rawValue >= 3840 && code.rawValue <= 4095
  }

  @available(macOS, introduced: 10.9) @available(iOS, introduced: 7.0)
  public var isUbiquitousFileError: Bool {
    return code.rawValue >= 4352 && code.rawValue <= 4607
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  public var isUserActivityError: Bool {
    return code.rawValue >= 4608 && code.rawValue <= 4863
  }

  public var isValidationError: Bool {
    return code.rawValue >= 1024 && code.rawValue <= 2047
  }

  @available(macOS, introduced: 10.8) @available(iOS, introduced: 6.0)
  public var isXPCConnectionError: Bool {
    return code.rawValue >= 4096 && code.rawValue <= 4224
  }
}

extension CocoaError.Code {
  @available(*, unavailable, renamed: "fileNoSuchFile")
  public static var FileNoSuchFileError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileLocking")
  public static var FileLockingError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileReadUnknown")
  public static var FileReadUnknownError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileReadNoPermission")
  public static var FileReadNoPermissionError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileReadInvalidFileName")
  public static var FileReadInvalidFileNameError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileReadCorruptFile")
  public static var FileReadCorruptFileError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileReadNoSuchFile")
  public static var FileReadNoSuchFileError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileReadInapplicableStringEncoding")
  public static var FileReadInapplicableStringEncodingError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileReadUnsupportedScheme")
  public static var FileReadUnsupportedSchemeError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileReadTooLarge")
  public static var FileReadTooLargeError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileReadUnknownStringEncoding")
  public static var FileReadUnknownStringEncodingError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileWriteUnknown")
  public static var FileWriteUnknownError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileWriteNoPermission")
  public static var FileWriteNoPermissionError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileWriteInvalidFileName")
  public static var FileWriteInvalidFileNameError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileWriteFileExists")
  public static var FileWriteFileExistsError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileWriteInapplicableStringEncoding")
  public static var FileWriteInapplicableStringEncodingError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileWriteUnsupportedScheme")
  public static var FileWriteUnsupportedSchemeError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileWriteOutOfSpace")
  public static var FileWriteOutOfSpaceError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileWriteVolumeReadOnly")
  public static var FileWriteVolumeReadOnlyError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileManagerUnmountUnknown")
  public static var FileManagerUnmountUnknownError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileManagerUnmountBusy")
  public static var FileManagerUnmountBusyError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "keyValueValidation")
  public static var KeyValueValidationError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "formatting")
  public static var FormattingError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "userCancelled")
  public static var UserCancelledError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "featureUnsupported")
  public static var FeatureUnsupportedError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "executableNotLoadable")
  public static var ExecutableNotLoadableError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "executableArchitectureMismatch")
  public static var ExecutableArchitectureMismatchError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "executableRuntimeMismatch")
  public static var ExecutableRuntimeMismatchError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "executableLoad")
  public static var ExecutableLoadError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "executableLink")
  public static var ExecutableLinkError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "propertyListReadCorrupt")
  public static var PropertyListReadCorruptError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "propertyListReadUnknownVersion")
  public static var PropertyListReadUnknownVersionError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "propertyListReadStream")
  public static var PropertyListReadStreamError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "propertyListWriteStream")
  public static var PropertyListWriteStreamError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "propertyListWriteInvalid")
  public static var PropertyListWriteInvalidError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "xpcConnectionInterrupted")
  public static var XPCConnectionInterrupted: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "xpcConnectionInvalid")
  public static var XPCConnectionInvalid: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "xpcConnectionReplyInvalid")
  public static var XPCConnectionReplyInvalid: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "ubiquitousFileUnavailable")
  public static var UbiquitousFileUnavailableError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "ubiquitousFileNotUploadedDueToQuota")
  public static var UbiquitousFileNotUploadedDueToQuotaError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "ubiquitousFileUbiquityServerNotAvailable")
  public static var UbiquitousFileUbiquityServerNotAvailable: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "userActivityHandoffFailed")
  public static var UserActivityHandoffFailedError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "userActivityConnectionUnavailable")
  public static var UserActivityConnectionUnavailableError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "userActivityRemoteApplicationTimedOut")
  public static var UserActivityRemoteApplicationTimedOutError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "userActivityHandoffUserInfoTooLarge")
  public static var UserActivityHandoffUserInfoTooLargeError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "coderReadCorrupt")
  public static var CoderReadCorruptError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "coderValueNotFound")
  public static var CoderValueNotFoundError: CocoaError.Code {
    fatalError("unavailable accessor can't be called")
  }
}

/// Describes errors in the URL error domain.
