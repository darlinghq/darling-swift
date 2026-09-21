//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// Reduced for Darling: only the coding-key helpers AttributedString's
// Codable conformances need. The rest of this file is JSON BufferView support.

package enum EmptyCodingKeys: CodingKey { }
package enum DefaultAssociatedValueCodingKeys1: String, CodingKey {
    case _0
}
