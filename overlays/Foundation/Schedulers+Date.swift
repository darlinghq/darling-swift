//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
// Only support 64bit
#if !(os(iOS) && (arch(i386) || arch(arm)))

@_exported import Foundation // Clang module

// Darling: Date.swift of this overlay already declares distance(to:) and advanced(by:), which this file defined in
// the original; only the Stride typealias that Combine's Scheduler support names is left here.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Date /* : Strideable */ {
    public typealias Stride = TimeInterval
}

#endif
