//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// From swift-foundation dbacc677 NumberFormatStyleConfiguration.swift; the rest of that file needs
// internals this overlay lacks. Only the ICU-only `icuContext` accessor was dropped.

@available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
public struct FormatStyleCapitalizationContext : Codable, Hashable, Sendable {

    internal enum Option: Int, Codable, Hashable {
        case unknown
        case standalone
        case listItem
        case beginningOfSentence
        case middleOfSentence
    }

    internal var option: Option

    private init(_ option: Option) {
        self.option = option
    }

#if FOUNDATION_FRAMEWORK
    var formatterContext: Formatter.Context {
        switch option {
        case .unknown:
            return .unknown
        case .standalone:
            return .standalone
        case .listItem:
            return .listItem
        case .beginningOfSentence:
            return .beginningOfSentence
        case .middleOfSentence:
            return .middleOfSentence
        }
    }
#endif // FOUNDATION_FRAMEWORK

    public static var unknown : FormatStyleCapitalizationContext {
        .init(.unknown)
    }

    /// For stand-alone usage, such as an isolated name on a calendar page.
    public static var standalone : FormatStyleCapitalizationContext {
        .init(.standalone)
    }

    /// For use in a UI list or menu item.
    public static var listItem : FormatStyleCapitalizationContext {
        .init(.listItem)
    }

    public static var beginningOfSentence : FormatStyleCapitalizationContext {
        .init(.beginningOfSentence)
    }

    public static var middleOfSentence : FormatStyleCapitalizationContext {
        .init(.middleOfSentence)
    }
}
