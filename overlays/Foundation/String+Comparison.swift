//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// Reduced for Darling: only the UTF8 code-unit constants StringBlocks.swift uses.
// The rest of this file is the pure-Swift string comparison implementation, which
// needs the Unicode scalar property tables (UnicodeScalar.swift,
// BuiltInUnicodeScalarSet.swift) that this overlay does not vendor.

package extension UTF8.CodeUnit {
    static let newline: Self = 0x0A
    static let carriageReturn: Self = 0x0D
}
