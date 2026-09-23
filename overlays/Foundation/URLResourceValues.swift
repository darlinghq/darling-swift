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

// From release/5.4 stdlib/public/Darwin/Foundation/URL.swift: URLResourceValues and
// URL.resourceValues(forKeys:) over Darling's -resourceValuesForKeys:error:.
// Darling declares the NSURL*Key constants as plain NSString, so the keys are built with URLResourceKey(rawValue:).

@_exported import Foundation // Clang module

public struct URLResourceValues {
    fileprivate var _values: [URLResourceKey: Any]

    public init() {
        _values = [:]
    }

    fileprivate init(values: [URLResourceKey: Any]) {
        _values = values
    }

    private func _get<T>(_ key : URLResourceKey) -> T? {
        return _values[key] as? T
    }

    private func _number(_ key: URLResourceKey) -> NSNumber? {
        return _get(key)
    }

    /// The date the resource was created.
    public var creationDate: Date? {
        return _get(URLResourceKey(rawValue: NSURLCreationDateKey))
    }

    public var isRegularFile: Bool? {
        return _number(URLResourceKey(rawValue: NSURLIsRegularFileKey))?.boolValue()
    }

    public var isDirectory: Bool? {
        return _number(URLResourceKey(rawValue: NSURLIsDirectoryKey))?.boolValue()
    }

    public var isSymbolicLink: Bool? {
        return _number(URLResourceKey(rawValue: NSURLIsSymbolicLinkKey))?.boolValue()
    }

    public var fileSize: Int? {
        return _number(URLResourceKey(rawValue: NSURLFileSizeKey))?.integerValue()
    }
}

extension URL {
    /// Return a collection of resource values identified by the given resource keys.
    public func resourceValues(forKeys keys: Set<URLResourceKey>) throws -> URLResourceValues {
        let raw = try _bridgeToObjectiveC().resourceValues(forKeys: keys.map { $0.rawValue })
        var values: [URLResourceKey: Any] = [:]
        for (key, value) in raw {
            if let name = key as? String {
                values[URLResourceKey(rawValue: name)] = value
            }
        }
        return URLResourceValues(values: values)
    }
}
