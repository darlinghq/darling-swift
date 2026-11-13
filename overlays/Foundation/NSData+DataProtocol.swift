//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// From release/5.4 (apple/swift 845205b4407c) stdlib/public/Darwin/Foundation/NSData+DataProtocol.swift.



// Darling: NSData's accessors are methods and -enumerateByteRangesUsingBlock: is not declared, so the regions are the
// one contiguous range of -bytes, which Darling's NSData always provides.
extension NSData : DataProtocol {

    @nonobjc
    public var startIndex: Int { return 0 }

    @nonobjc
    public var endIndex: Int { return length() }

    @nonobjc
    public func lastRange<D, R>(of data: D, in r: R) -> Range<Int>? where D : DataProtocol, R : RangeExpression, NSData.Index == R.Bound {
        return Range<Int>(range(of: Data(data), options: .backwards, range: NSRange(r)))
    }

    @nonobjc
    public func firstRange<D, R>(of data: D, in r: R) -> Range<Int>? where D : DataProtocol, R : RangeExpression, NSData.Index == R.Bound {
        return Range<Int>(range(of: Data(data), options: [], range: NSRange(r)))
    }

    @nonobjc
    public var regions: [Data] {
        let count = length()
        guard count > 0 else { return [] }
        return [Data(bytesNoCopy: UnsafeMutableRawPointer(mutating: bytes!), count: count, deallocator: .custom({ (ptr: UnsafeMutableRawPointer, count: Int) -> Void in
            withExtendedLifetime(self) { }
        }))]
    }

    @nonobjc
    public subscript(position: Int) -> UInt8 {
        precondition(position >= 0 && position < length(), "NSData index out of range")
        return bytes!.load(fromByteOffset: position, as: UInt8.self)
    }
}
