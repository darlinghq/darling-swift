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

// From release/5.4 (apple/swift 845205b4407c) stdlib/public/Darwin/Foundation/NSTextCheckingResult.swift.


@_exported import Foundation // Clang module

//===----------------------------------------------------------------------===//
// TextChecking
//===----------------------------------------------------------------------===//

extension NSTextCheckingType {
    public static var allSystemTypes : NSTextCheckingType {
        return NSTextCheckingType(rawValue: 0xffffffff)
    }
    
    public static var allCustomTypes : NSTextCheckingType {
        return NSTextCheckingType(rawValue: 0xffffffff << 32)
    }
    
    public static var allTypes : NSTextCheckingType {
        return NSTextCheckingType(rawValue: UInt64.max)
    }
}
