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

// From release/5.4 stdlib/public/Darwin/Foundation/FileManager.swift, reduced to enumerator(at:...). Darling has no
// __NSFileManagerEnumeratorAtURL shim, so it calls -enumeratorAtURL:includingPropertiesForKeys:options:errorHandler:
// and bridges the handler's arguments.

@_exported import Foundation // Clang module

extension FileManager {
    @available(macOS 10.6, iOS 4.0, *)
    @nonobjc
    public func enumerator(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?,
                           options mask: NSDirectoryEnumerationOptions = NSDirectoryEnumerationOptions(rawValue: 0),
                           errorHandler handler: ((URL, Error) -> Bool)? = nil) -> NSDirectoryEnumerator? {
        return enumerator(at: url._bridgeToObjectiveC(), includingPropertiesForKeys: keys.map { $0.map { $0.rawValue } },
                          options: mask, errorHandler: { (url: NSURL?, error: NSError?) -> Bool in
            guard let h = handler else { return true }
            guard let url = url, let error = error else {
                fatalError("FileManager.enumerator(at:) error handler called without a URL or an error")
            }
            return h(URL._unconditionallyBridgeFromObjectiveC(url), error as Error)
        })
    }
}
