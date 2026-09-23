//===----------------------------------------------------------------------===//
//
// This source file is part of the darling-swift project.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
//===----------------------------------------------------------------------===//

// String.LocalizationValue, LocalizedStringResource and String(localized:), written for Darling from Apple's public
// API documentation (macOS 12/13 Foundation). Only the API macOS 26 apps import is provided; there's no
// AttributedString or FormatStyle support.
// A localization value keeps the format key built from its literal segments and interpolations ("Hello %@") and the
// interpolated arguments. Localizing looks the key up in the bundle's strings table and formats the result with the
// arguments.

@_exported import Foundation // Clang module

/// A value whose format specifier is used when it's interpolated into a `String.LocalizationValue`.
public protocol _FormatSpecifiable : Equatable {
    associatedtype _Arg : CVarArg
    var _arg: _Arg { get }
    var _specifier: String { get }
}

extension Int : _FormatSpecifiable {
    public var _arg: Int { return self }
    public var _specifier: String { return "%lld" }
}

extension Double : _FormatSpecifiable {
    public var _arg: Double { return self }
    public var _specifier: String { return "%lf" }
}

extension String {
    public struct LocalizationValue : ExpressibleByStringInterpolation, @unchecked Sendable {
        internal var _key: String
        internal var _arguments: [CVarArg]
        /// Whether `_key` is a format string built by interpolation (with "%" escaped), rather than a plain literal.
        internal var _isFormat: Bool
        /// Whether the key holds placeholder specifiers that have no arguments, so it can't be formatted.
        internal var _hasPlaceholder: Bool

        public init(_ value: String) {
            _key = value
            _arguments = []
            _isFormat = false
            _hasPlaceholder = false
        }

        public init(stringLiteral value: String) {
            self.init(value)
        }

        public init(stringInterpolation: StringInterpolation) {
            _key = stringInterpolation._key
            _arguments = stringInterpolation._arguments
            _isFormat = true
            _hasPlaceholder = stringInterpolation._hasPlaceholder
        }

        /// The localized format with the arguments substituted.
        internal func _formatted(_ format: String, locale: Locale?) -> String {
            guard _isFormat else { return format }
            guard !_hasPlaceholder else { return format.replacingOccurrences(of: "%%", with: "%") }
            return withVaList(_arguments) {
                NSString(format: format, locale: locale.map { $0 as NSLocale }, arguments: $0) as String
            }
        }

        public enum Placeholder : Hashable, Sendable {
            case int
            case unsignedInt
            case float
            case double
            case object
        }

        public struct StringInterpolation : StringInterpolationProtocol, @unchecked Sendable {
            internal var _key = ""
            internal var _arguments: [CVarArg] = []
            internal var _hasPlaceholder = false

            public init(literalCapacity: Int, interpolationCount: Int) {
                _key.reserveCapacity(literalCapacity + 2 * interpolationCount)
                _arguments.reserveCapacity(interpolationCount)
            }

            public mutating func appendLiteral(_ literal: String) {
                // A literal "%" must survive formatting.
                _key += literal.replacingOccurrences(of: "%", with: "%%")
            }

            public mutating func appendInterpolation(_ string: String) {
                _key += "%@"
                _arguments.append(string)
            }

            public mutating func appendInterpolation<T : _FormatSpecifiable>(_ value: T, specifier: String) {
                _key += specifier
                _arguments.append(value._arg)
            }

            public mutating func appendInterpolation<T : CustomLocalizedStringResourceConvertible>(_ value: T) {
                _key += "%@"
                _arguments.append(String(localized: value.localizedStringResource))
            }

            /// Adds a specifier to the key without an argument, for keys shared with other localized strings.
            public mutating func appendInterpolation(placeholder: Placeholder, specifier: String) {
                _key += specifier
                _hasPlaceholder = true
            }
        }
    }

    public init(localized keyAndValue: LocalizationValue, table: String? = nil, bundle: Bundle? = nil, locale: Locale = .current, comment: StaticString? = nil) {
        let bundle = bundle ?? Bundle.main
        let format = bundle.localizedString(forKey: keyAndValue._key, value: keyAndValue._key, table: table) ?? keyAndValue._key
        self = keyAndValue._formatted(format, locale: locale)
    }

    public init(localized key: StaticString, defaultValue: LocalizationValue, table: String? = nil, bundle: Bundle? = nil, locale: Locale = .current, comment: StaticString? = nil) {
        let bundle = bundle ?? Bundle.main
        let format = bundle.localizedString(forKey: key.description, value: defaultValue._key, table: table) ?? defaultValue._key
        self = defaultValue._formatted(format, locale: locale)
    }

    public init(localized resource: LocalizedStringResource) {
        let format = resource._bundle?.localizedString(forKey: resource.key, value: resource._defaultValue._key, table: resource.table) ?? resource._defaultValue._key
        self = resource._defaultValue._formatted(format, locale: resource.locale)
    }
}

/// A type that describes itself with a localized string resource.
public protocol CustomLocalizedStringResourceConvertible {
    var localizedStringResource: LocalizedStringResource { get }
}

/// A reference to a localizable string: its key, default value, table, locale and bundle, resolved when localized.
public struct LocalizedStringResource : ExpressibleByStringInterpolation, CustomLocalizedStringResourceConvertible, @unchecked Sendable {
    public typealias StringInterpolation = String.LocalizationValue.StringInterpolation

    public enum BundleDescription : @unchecked Sendable {
        case main
        case forClass(AnyClass)
        case atURL(URL)
    }

    public var key: String
    public var table: String?
    public var locale: Locale
    public var bundle: BundleDescription
    internal var _defaultValue: String.LocalizationValue

    public init(_ keyAndValue: String.LocalizationValue, table: String? = nil, locale: Locale = .current, bundle: BundleDescription = .main, comment: StaticString? = nil) {
        key = keyAndValue._key
        self.table = table
        self.locale = locale
        self.bundle = bundle
        _defaultValue = keyAndValue
    }

    public init(_ key: StaticString, defaultValue: String.LocalizationValue, table: String? = nil, locale: Locale = .current, bundle: BundleDescription = .main, comment: StaticString? = nil) {
        self.key = key.description
        self.table = table
        self.locale = locale
        self.bundle = bundle
        _defaultValue = defaultValue
    }

    public init(stringLiteral value: String) {
        self.init(String.LocalizationValue(value))
    }

    public init(stringInterpolation: StringInterpolation) {
        self.init(String.LocalizationValue(stringInterpolation: stringInterpolation))
    }

    public var localizedStringResource: LocalizedStringResource {
        return self
    }

    internal var _bundle: Bundle? {
        switch bundle {
        case .main: return Bundle.main
        case .forClass(let cls): return Bundle(for: cls)
        case .atURL(let url): return Bundle(url: url as NSURL)
        }
    }
}
