//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// Darling reimplementation of the four accessors that reach the Locale.Language, Locale.Region and
// Locale.Currency types vendored from swift-foundation's Locale+Components.swift and Locale+Language.swift.
//
// Upstream implements them in FoundationInternationalization (Locale+Components_ICU.swift and the _Locale
// protocol), reading the components straight out of ICU. This overlay's Locale is the Swift 5.4 SDK
// overlay's wrapper around NSLocale, so the components come from NSLocale instead: Darling's CoreFoundation
// backs the NSLocale* keys with its own ICU-backed CFLocale, which is the same data upstream reads.
//
// Nothing here invents a value. Each accessor returns nil exactly where NSLocale has no component to give.

@_exported import Foundation // Clang module

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
extension Locale {
    /// Returns the language of the locale.
    public var language: Language {
        return Language(
            languageCode: languageCode.map { Locale.LanguageCode($0) },
            script: scriptCode.map { Locale.Script($0) },
            region: regionCode.map { Locale.Region($0) })
    }

    /// Returns the region of the locale, or nil if it has none.
    ///
    /// Reads NSLocaleCountryCode, so an `rg` override in the identifier is honoured only as far as Darling's
    /// CFLocale honours it. Upstream distinguishes `Locale.region` from `Locale.language.region` on that key.
    public var region: Region? {
        return regionCode.map { Region($0) }
    }

    /// Returns the currency of the locale, or nil if it has none.
    public var currency: Currency? {
        return currencyCode.map { Currency($0) }
    }
}

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
extension Locale.Language {
    /// The language code of the language. Returns nil if it cannot be determined.
    ///
    /// Upstream falls back to parsing `components.identifier` with `uloc_getLanguage` when the stored code is
    /// nil. Every initializer this overlay ships stores the code directly, so there is no identifier left to
    /// parse and the stored value is the whole answer; nil here means the language really has no code.
    public var languageCode: Locale.LanguageCode? {
        return components.languageCode
    }
}
