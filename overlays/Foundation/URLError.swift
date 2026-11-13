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

// Adapted from swift-corelibs-foundation's Darwin Foundation overlay.
// Keep URL error codes aligned with Foundation's NSURLError domain.
@_exported import Foundation

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
