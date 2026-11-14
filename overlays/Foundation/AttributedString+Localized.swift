//===----------------------------------------------------------------------===//
//
// This source file is part of the darling-swift project.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
//===----------------------------------------------------------------------===//

// AttributedString(localized:), written for Darling from Apple's documentation and the SDK's Foundation.swiftinterface
// (see DARLING-CHANGES.md).

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributedString {
    public struct FormattingOptions : OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        /// Marks each replaced argument with `replacementIndex`, its 1-based position among the arguments.
        public static let applyReplacementIndexAttribute = FormattingOptions(rawValue: 1 << 0)
    }

    public struct InterpolationOptions : OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        /// Inserts the interpolated string with only its own attributes, not those of the text around it.
        public static let insertAttributesWithoutMerging = InterpolationOptions(rawValue: 1 << 0)
    }

    public init(localized key: String.LocalizationValue, options: FormattingOptions = [], table: String? = nil, bundle: Bundle? = nil, locale: Locale? = nil, comment: StaticString? = nil) {
        self.init(localized: key, options: options, table: table, bundle: bundle, locale: locale, comment: comment, including: AttributeScopes.FoundationAttributes.self)
    }

    public init(localized key: StaticString, defaultValue: String.LocalizationValue, options: FormattingOptions = [], table: String? = nil, bundle: Bundle? = nil, locale: Locale? = nil, comment: StaticString? = nil) {
        self.init(localized: key, defaultValue: defaultValue, options: options, table: table, bundle: bundle, locale: locale, comment: comment, including: AttributeScopes.FoundationAttributes.self)
    }

    public init<S : AttributeScope>(localized key: String.LocalizationValue, options: FormattingOptions = [], table: String? = nil, bundle: Bundle? = nil, locale: Locale? = nil, comment: StaticString? = nil, including scope: KeyPath<AttributeScopes, S.Type>) {
        self.init(localized: key, options: options, table: table, bundle: bundle, locale: locale, comment: comment, including: S.self)
    }

    public init<S : AttributeScope>(localized key: StaticString, defaultValue: String.LocalizationValue, options: FormattingOptions = [], table: String? = nil, bundle: Bundle? = nil, locale: Locale? = nil, comment: StaticString? = nil, including scope: KeyPath<AttributeScopes, S.Type>) {
        self.init(localized: key, defaultValue: defaultValue, options: options, table: table, bundle: bundle, locale: locale, comment: comment, including: S.self)
    }

    public init<S : AttributeScope>(localized key: String.LocalizationValue, options: FormattingOptions = [], table: String? = nil, bundle: Bundle? = nil, locale: Locale? = nil, comment: StaticString? = nil, including scope: S.Type) {
        let format = (bundle ?? Bundle.main).localizedString(forKey: key._key, value: key._key, table: table) ?? key._key
        self = key._localizedAttributedString(format, options: options, locale: locale ?? .current, scope: scope)
    }

    public init<S : AttributeScope>(localized key: StaticString, defaultValue: String.LocalizationValue, options: FormattingOptions = [], table: String? = nil, bundle: Bundle? = nil, locale: Locale? = nil, comment: StaticString? = nil, including scope: S.Type) {
        let format = (bundle ?? Bundle.main).localizedString(forKey: key.description, value: defaultValue._key, table: table) ?? defaultValue._key
        self = defaultValue._localizedAttributedString(format, options: options, locale: locale ?? .current, scope: scope)
    }

    @_disfavoredOverload
    public init(localized resource: LocalizedStringResource) {
        self.init(localized: resource, including: AttributeScopes.FoundationAttributes.self)
    }

    @_disfavoredOverload
    public init<S : AttributeScope>(localized resource: LocalizedStringResource, including scope: KeyPath<AttributeScopes, S.Type>) {
        self.init(localized: resource, including: S.self)
    }

    @_disfavoredOverload
    public init<S : AttributeScope>(localized resource: LocalizedStringResource, including scope: S.Type) {
        let format = resource._bundle?.localizedString(forKey: resource.key, value: resource._defaultValue._key, table: resource.table) ?? resource._defaultValue._key
        self = resource._defaultValue._localizedAttributedString(format, options: [], locale: resource.locale, scope: scope)
    }
}

extension String.LocalizationValue {
    /// `format`, a localization of this value's key, parsed as Markdown with this value's arguments substituted.
    internal func _localizedAttributedString<S : AttributeScope>(_ format: String, options: AttributedString.FormattingOptions, locale: Locale, scope: S.Type) -> AttributedString {
        let markdownOptions = AttributedString.MarkdownParsingOptions(allowsExtendedAttributes: true, interpretedSyntax: .inlineOnlyPreservingWhitespace, failurePolicy: .returnPartiallyParsedIfPossible)
        guard _isFormat else { return Self._parse(format, scope: scope, options: markdownOptions) }

        // Specifiers become private-use scalars the format doesn't contain, so Markdown can't read their `*`s.
        let scalars = format.unicodeScalars
        let used = Set(scalars)
        var candidates = (UInt32(0xF0000)...0xFFFFD).lazy.compactMap { Unicode.Scalar($0) }.filter { !used.contains($0) }.makeIterator()
        var specifiers: [Unicode.Scalar : _FormatSpecifier] = [:]
        var protected = String.UnicodeScalarView()
        var rest = scalars.startIndex
        for specifier in _FormatSpecifier.all(in: scalars) {
            protected.append(contentsOf: scalars[rest..<specifier.range.lowerBound])
            rest = specifier.range.upperBound
            if specifier.isPercent {
                protected.append("%")
            } else {
                guard let placeholder = candidates.next() else { preconditionFailure("no private-use scalar left for a format specifier") }
                specifiers[placeholder] = specifier
                protected.append(placeholder)
            }
        }
        protected.append(contentsOf: scalars[rest...])
        let parsed = Self._parse(String(protected), scope: scope, options: markdownOptions)

        var result = AttributedString()
        var nextArgument = 0
        var copied = parsed.startIndex
        var i = parsed.unicodeScalars.startIndex
        while i < parsed.unicodeScalars.endIndex {
            let next = parsed.unicodeScalars.index(after: i)
            if let specifier = specifiers[parsed.unicodeScalars[i]] {
                result.append(parsed[copied..<i])
                result.append(_replacement(for: specifier, attributes: parsed[i..<next].runs.first!.attributes, nextArgument: &nextArgument, options: options, locale: locale))
                copied = next
            }
            i = next
        }
        result.append(parsed[copied...])
        return result
    }

    private static func _parse<S : AttributeScope>(_ markdown: String, scope: S.Type, options: AttributedString.MarkdownParsingOptions) -> AttributedString {
        do {
            return try AttributedString(markdown: markdown, including: scope, options: options)
        } catch {
            // Under returnPartiallyParsedIfPossible only a missing cmark parser or extension throws.
            preconditionFailure("\(error)")
        }
    }

    /// The argument text for `specifier`, or the specifier itself when this value has no such argument
    /// (a placeholder key, or a translation naming more arguments than the key has).
    private func _replacement(for specifier: _FormatSpecifier, attributes: AttributeContainer, nextArgument: inout Int, options: AttributedString.FormattingOptions, locale: Locale) -> AttributedString {
        let unformatted = AttributedString(String(specifier.text), attributes: attributes)
        if _hasPlaceholder { return unformatted }
        var indices: [Int] = specifier.starIndices.map { star in
            if let star { return star }
            defer { nextArgument += 1 }
            return nextArgument
        }
        let valueIndex = specifier.argumentIndex ?? nextArgument
        nextArgument = valueIndex + 1
        indices.append(valueIndex)
        guard indices.allSatisfy({ $0 < _arguments.count }) else { return unformatted }

        var replacement: AttributedString
        if let attributed = _attributedArguments[valueIndex] {
            replacement = attributed.string
            if !attributed.options.contains(.insertAttributesWithoutMerging) {
                replacement.mergeAttributes(attributes, mergePolicy: .keepCurrent)
            }
        } else {
            let text = String(format: specifier.format, locale: locale, arguments: indices.map { _arguments[$0] })
            replacement = AttributedString(text, attributes: attributes)
        }
        if options.contains(.applyReplacementIndexAttribute) {
            replacement.replacementIndex = valueIndex + 1
        }
        return replacement
    }
}

/// One `%` conversion in a localized format.
private struct _FormatSpecifier {
    var range: Range<String.Index>
    var text: Substring.UnicodeScalarView
    /// The specifier with its `n$` positions removed, to format the collected arguments with.
    var format: String
    /// The 0-based argument index of a positional (`%2$@`) value.
    var argumentIndex: Int?
    /// One entry per `*` width or precision: its 0-based `*n$` index, or nil to take the next argument.
    var starIndices: [Int?]
    var isPercent: Bool

    static func all(in scalars: String.UnicodeScalarView) -> [_FormatSpecifier] {
        var specifiers: [_FormatSpecifier] = []
        var i = scalars.startIndex
        while i < scalars.endIndex {
            if scalars[i] == "%", let specifier = parse(scalars, at: i) {
                specifiers.append(specifier)
                i = specifier.range.upperBound
            } else {
                i = scalars.index(after: i)
            }
        }
        return specifiers
    }

    /// `%[n$][flags][width][.precision][length]conversion`, where width and precision may be `*` or `*n$`;
    /// nil if the text at `start` is not one.
    private static func parse(_ scalars: String.UnicodeScalarView, at start: String.Index) -> _FormatSpecifier? {
        var i = scalars.index(after: start)
        func peek() -> Unicode.Scalar? { i < scalars.endIndex ? scalars[i] : nil }
        func digits() -> String {
            var text = ""
            while let c = peek(), ("0"..."9").contains(c) {
                text.unicodeScalars.append(c)
                i = scalars.index(after: i)
            }
            return text
        }
        /// `n$` as a 0-based index, or nil (consuming nothing) if the text there isn't one.
        func position() -> Int? {
            let begin = i
            if let n = Int(digits()), n > 0, peek() == "$" {
                i = scalars.index(after: i)
                return n - 1
            }
            i = begin
            return nil
        }
        func specifier(format: String, argumentIndex: Int? = nil, starIndices: [Int?] = [], isPercent: Bool = false) -> _FormatSpecifier {
            let range = start..<scalars.index(after: i)
            return _FormatSpecifier(range: range, text: scalars[range], format: format,
                                    argumentIndex: argumentIndex, starIndices: starIndices, isPercent: isPercent)
        }
        if peek() == "%" { return specifier(format: "%%", isPercent: true) }
        var format = "%"
        let argumentIndex = position()
        while let c = peek(), "-+ #0'".unicodeScalars.contains(c) {
            format.unicodeScalars.append(c)
            i = scalars.index(after: i)
        }
        var starIndices: [Int?] = []
        func widthOrPrecision() {
            if peek() == "*" {
                format += "*"
                i = scalars.index(after: i)
                starIndices.append(position())
            } else {
                format += digits()
            }
        }
        widthOrPrecision()
        if peek() == "." {
            format += "."
            i = scalars.index(after: i)
            widthOrPrecision()
        }
        while let c = peek(), "hlqLzjt".unicodeScalars.contains(c) {
            format.unicodeScalars.append(c)
            i = scalars.index(after: i)
        }
        guard let conversion = peek(), "@dDiuUxXoOfFeEgGaAcCsSp".unicodeScalars.contains(conversion) else { return nil }
        format.unicodeScalars.append(conversion)
        return specifier(format: format, argumentIndex: argumentIndex, starIndices: starIndices)
    }
}
