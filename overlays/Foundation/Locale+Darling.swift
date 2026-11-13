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
internal import _FoundationICU

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

// The accessors below are ported from swift-foundation's
// FoundationInternationalization/Locale/Locale+Components_ICU.swift and Locale_ICU.swift, and call
// Darling's ICU 66 (libicucore) through `_FoundationICU` exactly as upstream does.

/// Runs an ICU "fill a char buffer" call, returning nil on failure or an empty result.
private func _icuString(_ body: (UnsafeMutablePointer<CChar>, Int32, inout UErrorCode) -> Int32) -> String? {
    let capacity = Int(ULOC_FULLNAME_CAPACITY) + 1
    return withUnsafeTemporaryAllocation(of: CChar.self, capacity: capacity) { buffer -> String? in
        var status = U_ZERO_ERROR
        let length = body(buffer.baseAddress!, Int32(capacity - 1), &status)
        guard status.rawValue <= U_ZERO_ERROR.rawValue, length > 0 else { return nil }
        buffer[Int(length)] = 0
        return String(cString: buffer.baseAddress!)
    }
}

private func _languageDirection(_ layoutType: ULayoutType) -> Locale.LanguageDirection {
    switch layoutType {
    case ULOC_LAYOUT_LTR: return .leftToRight
    case ULOC_LAYOUT_RTL: return .rightToLeft
    case ULOC_LAYOUT_TTB: return .topToBottom
    case ULOC_LAYOUT_BTT: return .bottomToTop
    default: return .unknown
    }
}

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
extension Locale {
    /// The numbering system of the locale: the `numbers` keyword if the identifier has one,
    /// otherwise the locale's default, `latn` if ICU cannot tell.
    public var numberingSystem: Locale.NumberingSystem {
        var status = U_ZERO_ERROR
        guard let system = unumsys_open(identifier, &status) else { return .latn }
        defer { unumsys_close(system) }
        guard status.rawValue <= U_ZERO_ERROR.rawValue, let name = unumsys_getName(system) else { return .latn }
        return Locale.NumberingSystem(String(cString: name))
    }
}

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
extension Locale.Language.Components {
    /// - Parameter identifier: Unicode language identifier, such as "en-US", "es-419", "zh-Hant-TW"
    public init(identifier: String) {
        let languageCode = _icuString { uloc_getLanguage(identifier, $0, $1, &$2) }
        let scriptCode = _icuString { uloc_getScript(identifier, $0, $1, &$2) }
        let countryCode = _icuString { uloc_getCountry(identifier, $0, $1, &$2) }
        self.init(languageCode: languageCode.map { Locale.LanguageCode($0) },
                  script: scriptCode.map { Locale.Script($0) },
                  region: countryCode.map { Locale.Region($0) })
    }
}

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
extension Locale.Language {
    /// Creates a `Language` with the language identifier
    /// - Parameter identifier: Unicode language identifier, such as "en-US", "es-419", "zh-Hant-TW"
    public init(identifier: String) {
        self = .init(components: Components(identifier: identifier))
    }

    /// Ordering of characters within a line.
    /// For example, left-to-right for English; top-to-bottom for Mongolian in the Mongolian Script
    public var characterDirection: Locale.LanguageDirection {
        var status = U_ZERO_ERROR
        let orientation = uloc_getCharacterOrientation(components.identifier, &status)
        guard status.rawValue <= U_ZERO_ERROR.rawValue else { return .unknown }
        return _languageDirection(orientation)
    }

    /// Returns a BCP-47 identifier that always includes the script: "zh-Hant-TW", "en-Latn-US"
    public var maximalIdentifier: String {
        let id = components.identifier
        guard !id.isEmpty else { return id }
        guard let likely = _icuString({ uloc_addLikelySubtags(id, $0, $1, &$2) }) else { return id }
        return _icuString({ uloc_toLanguageTag(likely, $0, $1, UBool(0), &$2) }) ?? id
    }
}
