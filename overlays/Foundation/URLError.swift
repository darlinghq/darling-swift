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

// From release/5.4 (apple/swift 845205b4407c) stdlib/public/Darwin/Foundation/NSError.swift, URLError and its error codes.

@_exported import Foundation // Clang module
import CoreFoundation

public struct URLError : _BridgedStoredNSError {
  public let _nsError: NSError

  public init(_nsError error: NSError) {
    precondition(error.domain() == NSURLErrorDomain)
    self._nsError = error
  }

  public static var errorDomain: String { return NSURLErrorDomain }

  public var hashValue: Int {
    return _nsError.hashValue
  }

  /// The error code itself.
  public struct Code : RawRepresentable, Hashable, _ErrorCodeProtocol {
    public typealias _ErrorType = URLError

    public let rawValue: Int

    public init(rawValue: Int) {
      self.rawValue = rawValue
    }
  }
}

extension URLError.Code {
  public static var unknown: URLError.Code {
    return URLError.Code(rawValue: -1)
  }
  public static var cancelled: URLError.Code {
    return URLError.Code(rawValue: -999)
  }
  public static var badURL: URLError.Code {
    return URLError.Code(rawValue: -1000)
  }
  public static var timedOut: URLError.Code {
    return URLError.Code(rawValue: -1001)
  }
  public static var unsupportedURL: URLError.Code {
    return URLError.Code(rawValue: -1002)
  }
  public static var cannotFindHost: URLError.Code {
    return URLError.Code(rawValue: -1003)
  }
  public static var cannotConnectToHost: URLError.Code {
    return URLError.Code(rawValue: -1004)
  }
  public static var networkConnectionLost: URLError.Code {
    return URLError.Code(rawValue: -1005)
  }
  public static var dnsLookupFailed: URLError.Code {
    return URLError.Code(rawValue: -1006)
  }
  public static var httpTooManyRedirects: URLError.Code {
    return URLError.Code(rawValue: -1007)
  }
  public static var resourceUnavailable: URLError.Code {
    return URLError.Code(rawValue: -1008)
  }
  public static var notConnectedToInternet: URLError.Code {
    return URLError.Code(rawValue: -1009)
  }
  public static var redirectToNonExistentLocation: URLError.Code {
    return URLError.Code(rawValue: -1010)
  }
  public static var badServerResponse: URLError.Code {
    return URLError.Code(rawValue: -1011)
  }
  public static var userCancelledAuthentication: URLError.Code {
    return URLError.Code(rawValue: -1012)
  }
  public static var userAuthenticationRequired: URLError.Code {
    return URLError.Code(rawValue: -1013)
  }
  public static var zeroByteResource: URLError.Code {
    return URLError.Code(rawValue: -1014)
  }
  public static var cannotDecodeRawData: URLError.Code {
    return URLError.Code(rawValue: -1015)
  }
  public static var cannotDecodeContentData: URLError.Code {
    return URLError.Code(rawValue: -1016)
  }
  public static var cannotParseResponse: URLError.Code {
    return URLError.Code(rawValue: -1017)
  }
  @available(macOS, introduced: 10.11) @available(iOS, introduced: 9.0)
  public static var appTransportSecurityRequiresSecureConnection: URLError.Code {
    return URLError.Code(rawValue: -1022)
  }
  public static var fileDoesNotExist: URLError.Code {
    return URLError.Code(rawValue: -1100)
  }
  public static var fileIsDirectory: URLError.Code {
    return URLError.Code(rawValue: -1101)
  }
  public static var noPermissionsToReadFile: URLError.Code {
    return URLError.Code(rawValue: -1102)
  }
  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  public static var dataLengthExceedsMaximum: URLError.Code {
    return URLError.Code(rawValue: -1103)
  }
  public static var secureConnectionFailed: URLError.Code {
    return URLError.Code(rawValue: -1200)
  }
  public static var serverCertificateHasBadDate: URLError.Code {
    return URLError.Code(rawValue: -1201)
  }
  public static var serverCertificateUntrusted: URLError.Code {
    return URLError.Code(rawValue: -1202)
  }
  public static var serverCertificateHasUnknownRoot: URLError.Code {
    return URLError.Code(rawValue: -1203)
  }
  public static var serverCertificateNotYetValid: URLError.Code {
    return URLError.Code(rawValue: -1204)
  }
  public static var clientCertificateRejected: URLError.Code {
    return URLError.Code(rawValue: -1205)
  }
  public static var clientCertificateRequired: URLError.Code {
    return URLError.Code(rawValue: -1206)
  }
  public static var cannotLoadFromNetwork: URLError.Code {
    return URLError.Code(rawValue: -2000)
  }
  public static var cannotCreateFile: URLError.Code {
    return URLError.Code(rawValue: -3000)
  }
  public static var cannotOpenFile: URLError.Code {
    return URLError.Code(rawValue: -3001)
  }
  public static var cannotCloseFile: URLError.Code {
    return URLError.Code(rawValue: -3002)
  }
  public static var cannotWriteToFile: URLError.Code {
    return URLError.Code(rawValue: -3003)
  }
  public static var cannotRemoveFile: URLError.Code {
    return URLError.Code(rawValue: -3004)
  }
  public static var cannotMoveFile: URLError.Code {
    return URLError.Code(rawValue: -3005)
  }
  public static var downloadDecodingFailedMidStream: URLError.Code {
    return URLError.Code(rawValue: -3006)
  }
  public static var downloadDecodingFailedToComplete: URLError.Code {
    return URLError.Code(rawValue: -3007)
  }

  @available(macOS, introduced: 10.7) @available(iOS, introduced: 3.0)
  public static var internationalRoamingOff: URLError.Code {
    return URLError.Code(rawValue: -1018)
  }

  @available(macOS, introduced: 10.7) @available(iOS, introduced: 3.0)
  public static var callIsActive: URLError.Code {
    return URLError.Code(rawValue: -1019)
  }

  @available(macOS, introduced: 10.7) @available(iOS, introduced: 3.0)
  public static var dataNotAllowed: URLError.Code {
    return URLError.Code(rawValue: -1020)
  }

  @available(macOS, introduced: 10.7) @available(iOS, introduced: 3.0)
  public static var requestBodyStreamExhausted: URLError.Code {
    return URLError.Code(rawValue: -1021)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  public static var backgroundSessionRequiresSharedContainer: URLError.Code {
    return URLError.Code(rawValue: -995)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  public static var backgroundSessionInUseByAnotherProcess: URLError.Code {
    return URLError.Code(rawValue: -996)
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  public static var backgroundSessionWasDisconnected: URLError.Code {
    return URLError.Code(rawValue: -997)
  }
}

extension URLError {
  /// Reasons used by URLError to indicate why a background URLSessionTask was cancelled.
  @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
  public enum BackgroundTaskCancelledReason : Int {
    case userForceQuitApplication
    case backgroundUpdatesDisabled
    case insufficientSystemResources
  }
}

extension URLError {
  /// Reasons used by URLError to indicate that a URLSessionTask failed because of unsatisfiable network constraints.
  @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
  public enum NetworkUnavailableReason : Int {
    case cellular
    case expensive
    case constrained
  }
}

// Darling's Foundation headers do not declare the two user-info keys below yet; they are the documented NSError
// user-info key names.
private let _NSURLErrorBackgroundTaskCancelledReasonKey = "NSURLErrorBackgroundTaskCancelledReasonKey"
private let _NSURLErrorNetworkUnavailableReasonKey = "NSURLErrorNetworkUnavailableReasonKey"

extension URLError {
  private var _nsUserInfo: [AnyHashable : Any] {
    return (self as NSError).userInfo() ?? [:]
  }

  /// The URL which caused a load to fail.
  public var failingURL: URL? {
    return _nsUserInfo[NSURLErrorFailingURLErrorKey as NSString] as? URL
  }

  /// The string for the URL which caused a load to fail. 
  public var failureURLString: String? {
    return _nsUserInfo[NSURLErrorFailingURLStringErrorKey as NSString] as? String
  }

  /// The state of a failed SSL handshake.
  public var failureURLPeerTrust: SecTrust? {
    if let secTrust = _nsUserInfo[NSURLErrorFailingURLPeerTrustErrorKey as NSString] {
      return (secTrust as! SecTrust)
    }

    return nil
  }

  /// The reason why a background URLSessionTask was cancelled.
  @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
  public var backgroundTaskCancelledReason: BackgroundTaskCancelledReason? {
    return (_nsUserInfo[_NSURLErrorBackgroundTaskCancelledReasonKey] as? Int).flatMap(BackgroundTaskCancelledReason.init(rawValue:))
  }

  /// The reason why the network is unavailable when the task failed due to unsatisfiable network constraints.
  @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
  public var networkUnavailableReason: NetworkUnavailableReason? {
    return (_nsUserInfo[_NSURLErrorNetworkUnavailableReasonKey] as? Int).flatMap(NetworkUnavailableReason.init(rawValue:))
  }

  /// An opaque data blob to resume a failed download task.
  @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
  public var downloadTaskResumeData: Data? {
    return _nsUserInfo[NSURLSessionDownloadTaskResumeData] as? Data
  }
}

extension URLError {
  public static var unknown: URLError.Code {
    return .unknown
  }

  public static var cancelled: URLError.Code {
    return .cancelled
  }

  public static var badURL: URLError.Code {
    return .badURL
  }

  public static var timedOut: URLError.Code {
    return .timedOut
  }

  public static var unsupportedURL: URLError.Code {
    return .unsupportedURL
  }

  public static var cannotFindHost: URLError.Code {
    return .cannotFindHost
  }

  public static var cannotConnectToHost: URLError.Code {
    return .cannotConnectToHost
  }

  public static var networkConnectionLost: URLError.Code {
    return .networkConnectionLost
  }

  public static var dnsLookupFailed: URLError.Code {
    return .dnsLookupFailed
  }

  public static var httpTooManyRedirects: URLError.Code {
    return .httpTooManyRedirects
  }

  public static var resourceUnavailable: URLError.Code {
    return .resourceUnavailable
  }

  public static var notConnectedToInternet: URLError.Code {
    return .notConnectedToInternet
  }

  public static var redirectToNonExistentLocation: URLError.Code {
    return .redirectToNonExistentLocation
  }

  public static var badServerResponse: URLError.Code {
    return .badServerResponse
  }

  public static var userCancelledAuthentication: URLError.Code {
    return .userCancelledAuthentication
  }

  public static var userAuthenticationRequired: URLError.Code {
    return .userAuthenticationRequired
  }

  public static var zeroByteResource: URLError.Code {
    return .zeroByteResource
  }

  public static var cannotDecodeRawData: URLError.Code {
    return .cannotDecodeRawData
  }

  public static var cannotDecodeContentData: URLError.Code {
    return .cannotDecodeContentData
  }

  public static var cannotParseResponse: URLError.Code {
    return .cannotParseResponse
  }

  @available(macOS, introduced: 10.11) @available(iOS, introduced: 9.0)
  public static var appTransportSecurityRequiresSecureConnection: URLError.Code {
    return .appTransportSecurityRequiresSecureConnection
  }

  public static var fileDoesNotExist: URLError.Code {
    return .fileDoesNotExist
  }

  public static var fileIsDirectory: URLError.Code {
    return .fileIsDirectory
  }

  public static var noPermissionsToReadFile: URLError.Code {
    return .noPermissionsToReadFile
  }

  @available(macOS, introduced: 10.5) @available(iOS, introduced: 2.0)
  public static var dataLengthExceedsMaximum: URLError.Code {
    return .dataLengthExceedsMaximum
  }

  public static var secureConnectionFailed: URLError.Code {
    return .secureConnectionFailed
  }

  public static var serverCertificateHasBadDate: URLError.Code {
    return .serverCertificateHasBadDate
  }

  public static var serverCertificateUntrusted: URLError.Code {
    return .serverCertificateUntrusted
  }

  public static var serverCertificateHasUnknownRoot: URLError.Code {
    return .serverCertificateHasUnknownRoot
  }

  public static var serverCertificateNotYetValid: URLError.Code {
    return .serverCertificateNotYetValid
  }

  public static var clientCertificateRejected: URLError.Code {
    return .clientCertificateRejected
  }

  public static var clientCertificateRequired: URLError.Code {
    return .clientCertificateRequired
  }

  public static var cannotLoadFromNetwork: URLError.Code {
    return .cannotLoadFromNetwork
  }

  public static var cannotCreateFile: URLError.Code {
    return .cannotCreateFile
  }

  public static var cannotOpenFile: URLError.Code {
    return .cannotOpenFile
  }

  public static var cannotCloseFile: URLError.Code {
    return .cannotCloseFile
  }

  public static var cannotWriteToFile: URLError.Code {
    return .cannotWriteToFile
  }

  public static var cannotRemoveFile: URLError.Code {
    return .cannotRemoveFile
  }

  public static var cannotMoveFile: URLError.Code {
    return .cannotMoveFile
  }

  public static var downloadDecodingFailedMidStream: URLError.Code {
    return .downloadDecodingFailedMidStream
  }

  public static var downloadDecodingFailedToComplete: URLError.Code {
    return .downloadDecodingFailedToComplete
  }

  @available(macOS, introduced: 10.7) @available(iOS, introduced: 3.0)
  public static var internationalRoamingOff: URLError.Code {
    return .internationalRoamingOff
  }

  @available(macOS, introduced: 10.7) @available(iOS, introduced: 3.0)
  public static var callIsActive: URLError.Code {
    return .callIsActive
  }

  @available(macOS, introduced: 10.7) @available(iOS, introduced: 3.0)
  public static var dataNotAllowed: URLError.Code {
    return .dataNotAllowed
  }

  @available(macOS, introduced: 10.7) @available(iOS, introduced: 3.0)
  public static var requestBodyStreamExhausted: URLError.Code {
    return .requestBodyStreamExhausted
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  public static var backgroundSessionRequiresSharedContainer: Code {
    return .backgroundSessionRequiresSharedContainer
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  public static var backgroundSessionInUseByAnotherProcess: Code {
    return .backgroundSessionInUseByAnotherProcess
  }

  @available(macOS, introduced: 10.10) @available(iOS, introduced: 8.0)
  public static var backgroundSessionWasDisconnected: Code {
    return .backgroundSessionWasDisconnected
  }
}

extension URLError {
  @available(*, unavailable, renamed: "unknown")
  public static var Unknown: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "cancelled")
  public static var Cancelled: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "badURL")
  public static var BadURL: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "timedOut")
  public static var TimedOut: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "unsupportedURL")
  public static var UnsupportedURL: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "cannotFindHost")
  public static var CannotFindHost: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "cannotConnectToHost")
  public static var CannotConnectToHost: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "networkConnectionLost")
  public static var NetworkConnectionLost: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "dnsLookupFailed")
  public static var DNSLookupFailed: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "httpTooManyRedirects")
  public static var HTTPTooManyRedirects: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "resourceUnavailable")
  public static var ResourceUnavailable: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "notConnectedToInternet")
  public static var NotConnectedToInternet: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "redirectToNonExistentLocation")
  public static var RedirectToNonExistentLocation: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "badServerResponse")
  public static var BadServerResponse: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "userCancelledAuthentication")
  public static var UserCancelledAuthentication: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "userAuthenticationRequired")
  public static var UserAuthenticationRequired: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "zeroByteResource")
  public static var ZeroByteResource: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "cannotDecodeRawData")
  public static var CannotDecodeRawData: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "cannotDecodeContentData")
  public static var CannotDecodeContentData: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "cannotParseResponse")
  public static var CannotParseResponse: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "appTransportSecurityRequiresSecureConnection")
  public static var AppTransportSecurityRequiresSecureConnection: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileDoesNotExist")
  public static var FileDoesNotExist: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "fileIsDirectory")
  public static var FileIsDirectory: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "noPermissionsToReadFile")
  public static var NoPermissionsToReadFile: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "dataLengthExceedsMaximum")
  public static var DataLengthExceedsMaximum: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "secureConnectionFailed")
  public static var SecureConnectionFailed: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "serverCertificateHasBadDate")
  public static var ServerCertificateHasBadDate: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "serverCertificateUntrusted")
  public static var ServerCertificateUntrusted: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "serverCertificateHasUnknownRoot")
  public static var ServerCertificateHasUnknownRoot: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "serverCertificateNotYetValid")
  public static var ServerCertificateNotYetValid: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "clientCertificateRejected")
  public static var ClientCertificateRejected: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "clientCertificateRequired")
  public static var ClientCertificateRequired: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "cannotLoadFromNetwork")
  public static var CannotLoadFromNetwork: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "cannotCreateFile")
  public static var CannotCreateFile: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "cannotOpenFile")
  public static var CannotOpenFile: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "cannotCloseFile")
  public static var CannotCloseFile: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "cannotWriteToFile")
  public static var CannotWriteToFile: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "cannotRemoveFile")
  public static var CannotRemoveFile: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "cannotMoveFile")
  public static var CannotMoveFile: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "downloadDecodingFailedMidStream")
  public static var DownloadDecodingFailedMidStream: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "downloadDecodingFailedToComplete")
  public static var DownloadDecodingFailedToComplete: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "internationalRoamingOff")
  public static var InternationalRoamingOff: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "callIsActive")
  public static var CallIsActive: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "dataNotAllowed")
  public static var DataNotAllowed: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "requestBodyStreamExhausted")
  public static var RequestBodyStreamExhausted: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "backgroundSessionRequiresSharedContainer")
  public static var BackgroundSessionRequiresSharedContainer: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "backgroundSessionInUseByAnotherProcess")
  public static var BackgroundSessionInUseByAnotherProcess: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }

  @available(*, unavailable, renamed: "backgroundSessionWasDisconnected")
  public static var BackgroundSessionWasDisconnected: URLError.Code {
    fatalError("unavailable accessor can't be called")
  }
}

/// Describes an error in the POSIX error domain.
