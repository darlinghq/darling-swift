//===----------------------------------------------------------------------===//
//
// This source file is part of the darling-swift project.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
//===----------------------------------------------------------------------===//

// AttributedString's Markdown initializers over swift-cmark, written for Darling because swift-foundation does not
// ship them (its issue #44). DARLING-CHANGES.md describes the mapping and what is left out.

internal import cmark_gfm
internal import cmark_gfm_extensions
@_spi(Reflection) import Swift

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributedString {
    public struct MarkdownParsingOptions : Sendable {
        public enum FailurePolicy : Int, Sendable {
            case throwError
            case returnPartiallyParsedIfPossible
        }

        public enum InterpretedSyntax : Int, Sendable {
            case full
            case inlineOnly
            case inlineOnlyPreservingWhitespace
        }

        public var allowsExtendedAttributes: Bool
        public var interpretedSyntax: InterpretedSyntax
        public var failurePolicy: FailurePolicy
        public var languageCode: String?
        @available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
        public var appliesSourcePositionAttributes: Bool

        public init(allowsExtendedAttributes: Bool = false, interpretedSyntax: InterpretedSyntax = .full, failurePolicy: FailurePolicy = .throwError, languageCode: String? = nil) {
            self.init(allowsExtendedAttributes: allowsExtendedAttributes, interpretedSyntax: interpretedSyntax, failurePolicy: failurePolicy, languageCode: languageCode, appliesSourcePositionAttributes: false)
        }

        @available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
        public init(allowsExtendedAttributes: Bool = false, interpretedSyntax: InterpretedSyntax = .full, failurePolicy: FailurePolicy = .throwError, languageCode: String? = nil, appliesSourcePositionAttributes: Bool = false) {
            self.allowsExtendedAttributes = allowsExtendedAttributes
            self.interpretedSyntax = interpretedSyntax
            self.failurePolicy = failurePolicy
            self.languageCode = languageCode
            self.appliesSourcePositionAttributes = appliesSourcePositionAttributes
        }
    }

    /// Where a run's text is in the Markdown source: 1-based lines, and 1-based columns counted in UTF-8 bytes.
    @available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
    public struct MarkdownSourcePosition : Hashable, Codable, Sendable {
        public let startLine: Int
        public let startColumn: Int
        public let endLine: Int
        public let endColumn: Int

        public init(startLine: Int, startColumn: Int, endLine: Int, endColumn: Int) {
            self.startLine = startLine
            self.startColumn = startColumn
            self.endLine = endLine
            self.endColumn = endColumn
        }
    }

    public init<S : AttributeScope>(markdown: String, including scope: KeyPath<AttributeScopes, S.Type>, options: MarkdownParsingOptions = .init(), baseURL: URL? = nil) throws {
        try self.init(markdown: markdown, including: S.self, options: options, baseURL: baseURL)
    }

    public init(markdown: String, options: MarkdownParsingOptions = .init(), baseURL: URL? = nil) throws {
        try self.init(markdown: markdown, including: AttributeScopes.FoundationAttributes.self, options: options, baseURL: baseURL)
    }

    public init<S : AttributeScope>(markdown: String, including scope: S.Type, options: MarkdownParsingOptions = .init(), baseURL: URL? = nil) throws {
        var translator = _MarkdownTranslator(scope: scope, options: options, baseURL: baseURL)
        self = try translator.translate(Array(markdown.utf8))
    }

    public init<S : AttributeScope>(markdown: Data, including scope: KeyPath<AttributeScopes, S.Type>, options: MarkdownParsingOptions = .init(), baseURL: URL? = nil) throws {
        try self.init(markdown: markdown, including: S.self, options: options, baseURL: baseURL)
    }

    public init(markdown: Data, options: MarkdownParsingOptions = .init(), baseURL: URL? = nil) throws {
        try self.init(markdown: markdown, including: AttributeScopes.FoundationAttributes.self, options: options, baseURL: baseURL)
    }

    /// Invalid UTF-8 is an error, unless the failure policy allows a partial result, in which case cmark replaces
    /// each invalid sequence with U+FFFD.
    public init<S : AttributeScope>(markdown: Data, including scope: S.Type, options: MarkdownParsingOptions = .init(), baseURL: URL? = nil) throws {
        if options.failurePolicy == .throwError && String(data: markdown, encoding: .utf8) == nil {
            throw _MarkdownTranslator.error("The Markdown data is not valid UTF-8")
        }
        var translator = _MarkdownTranslator(scope: scope, options: options, baseURL: baseURL)
        self = try translator.translate([UInt8](markdown))
    }

    public init<S : AttributeScope>(contentsOf url: URL, including scope: KeyPath<AttributeScopes, S.Type>, options: MarkdownParsingOptions = .init(), baseURL: URL? = nil) throws {
        try self.init(contentsOf: url, including: S.self, options: options, baseURL: baseURL)
    }

    public init(contentsOf url: URL, options: MarkdownParsingOptions = .init(), baseURL: URL? = nil) throws {
        try self.init(contentsOf: url, including: AttributeScopes.FoundationAttributes.self, options: options, baseURL: baseURL)
    }

    /// Links resolve against `baseURL`, or against `url` itself when `baseURL` is nil.
    public init<S : AttributeScope>(contentsOf url: URL, including scope: S.Type, options: MarkdownParsingOptions = .init(), baseURL: URL? = nil) throws {
        try self.init(markdown: try Data(contentsOf: url), including: scope, options: options, baseURL: baseURL ?? url)
    }
}

/// Builds an AttributedString from cmark's tree, walked with cmark's iterator and an explicit stack so that deeply
/// nested input can't overflow the call stack.
private struct _MarkdownTranslator {
    typealias Node = UnsafeMutablePointer<cmark_node>

    /// An open container node: the attributes its content inherits and the block it opened, if any.
    struct Frame {
        var attributes: AttributeContainer
        var intent: PresentationIntent.IntentType?
        /// A list's next item ordinal, a table's body row count, or a row's cell count.
        var counter = 0
    }

    let options: AttributedString.MarkdownParsingOptions
    let baseURL: URL?
    let markdownKeys: [String : any MarkdownDecodableAttributedStringKey.Type]
    var result = AttributedString()
    var stack: [Frame] = []
    var nextIdentity = 1

    static let urlCharacters = CharacterSet(charactersIn: "!#$%&'()*+,-./0123456789:;=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]_abcdefghijklmnopqrstuvwxyz~")

    init<S : AttributeScope>(scope: S.Type, options: AttributedString.MarkdownParsingOptions, baseURL: URL?) {
        self.options = options
        self.baseURL = baseURL
        markdownKeys = options.allowsExtendedAttributes ? _markdownDecodableKeys(in: scope) : [:]
    }

    static func error(_ description: String) -> CocoaError {
        CocoaError(CocoaError.Code(rawValue: NSFormattingError), userInfo: [NSDebugDescriptionErrorKey: description])
    }

    mutating func translate(_ source: [UInt8]) throws -> AttributedString {
        cmark_gfm_core_extensions_ensure_registered()
        var cmarkOptions = CMARK_OPT_VALIDATE_UTF8
        switch options.interpretedSyntax {
        case .full: break
        case .inlineOnly: cmarkOptions |= CMARK_OPT_INLINE_ONLY
        case .inlineOnlyPreservingWhitespace:
            // cmark-gfm.h's CMARK_OPT_PRESERVE_WHITESPACE, ((1 << 19) | CMARK_OPT_INLINE_ONLY), which Swift can't import.
            cmarkOptions |= (1 << 19) | CMARK_OPT_INLINE_ONLY
        }
        guard let parser = cmark_parser_new(cmarkOptions) else { throw Self.error("cmark could not create a parser") }
        defer { cmark_parser_free(parser) }
        for name in ["table", "strikethrough", "autolink"] {
            guard let ext = cmark_find_syntax_extension(name) else { throw Self.error("cmark has no \(name) extension") }
            cmark_parser_attach_syntax_extension(parser, ext)
        }
        if !source.isEmpty {
            source.withUnsafeBufferPointer { bytes in
                bytes.withMemoryRebound(to: CChar.self) { cmark_parser_feed(parser, $0.baseAddress, $0.count) }
            }
        }
        guard let document = cmark_parser_finish(parser) else { throw Self.error("cmark could not parse the document") }
        defer { cmark_node_free(document) }
        guard let iterator = cmark_iter_new(document) else { throw Self.error("cmark could not walk the document") }
        defer { cmark_iter_free(iterator) }

        var root = AttributeContainer()
        root.languageIdentifier = options.languageCode
        stack = [Frame(attributes: root)]
        while true {
            let event = cmark_iter_next(iterator)
            if event == CMARK_EVENT_DONE { break }
            let node = cmark_iter_get_node(iterator)!
            if event == CMARK_EVENT_EXIT {
                stack.removeLast()
            } else {
                try enter(node)
            }
        }
        return result
    }

    /// Handles a leaf, or pushes the frame for a container; cmark reports every container's exit.
    mutating func enter(_ node: Node) throws {
        var attributes = stack[stack.count - 1].attributes
        func add(_ intent: InlinePresentationIntent) {
            attributes.inlinePresentationIntent = (attributes.inlinePresentationIntent ?? []).union(intent)
        }
        switch Self.type(of: node) {
        // Leaves
        case "text":
            append(Self.string(cmark_node_get_literal(node)), attributes: attributes, node: node)
        case "softbreak":
            add(.softBreak)
            append(" ", attributes: attributes, node: node)
        case "linebreak":
            add(.lineBreak)
            append("\n", attributes: attributes, node: node)
        case "code":
            add(.code)
            append(Self.string(cmark_node_get_literal(node)), attributes: attributes, node: node)
        case "html_inline":
            add(.inlineHTML)
            append(Self.string(cmark_node_get_literal(node)), attributes: attributes, node: node)
        case "code_block":
            let info = Self.string(cmark_node_get_fence_info(node)).split(whereSeparator: \.isWhitespace).first.map(String.init)
            attributes.presentationIntent = presentationIntent(adding: makeIntent(.codeBlock(languageHint: info)))
            append(Self.string(cmark_node_get_literal(node)), attributes: attributes, node: node)
        case "html_block":
            attributes.presentationIntent = presentationIntent(adding: nil)
            add(.blockHTML)
            append(Self.string(cmark_node_get_literal(node)), attributes: attributes, node: node)
        case "thematic_break":
            // A thematic break has no text for an attribute to cover.
            break

        // Blocks
        case "paragraph":
            pushBlock(.paragraph, attributes: attributes, textBlock: true)
        case "heading":
            pushBlock(.header(level: Int(cmark_node_get_heading_level(node))), attributes: attributes, textBlock: true)
        case "block_quote":
            pushBlock(.blockQuote, attributes: attributes, textBlock: false)
        case "list":
            let ordered = cmark_node_get_list_type(node) == CMARK_ORDERED_LIST
            if ordered {
                attributes.listItemDelimiter = cmark_node_get_list_delim(node) == CMARK_PAREN_DELIM ? ")" : "."
            } else {
                switch cmark_node_get_list_marker(node) {
                case CMARK_PLUS_LIST_MARKER: attributes.listItemDelimiter = "+"
                case CMARK_ASTERISK_LIST_MARKER: attributes.listItemDelimiter = "*"
                default: attributes.listItemDelimiter = "-"
                }
            }
            pushBlock(ordered ? .orderedList : .unorderedList, attributes: attributes, textBlock: false)
            stack[stack.count - 1].counter = ordered ? Int(cmark_node_get_list_start(node)) : 1
        case "item":
            let ordinal = stack[stack.count - 1].counter
            stack[stack.count - 1].counter += 1
            pushBlock(.listItem(ordinal: ordinal), attributes: attributes, textBlock: false)
        case "table":
            let alignments = cmark_gfm_extensions_get_table_alignments(node)
            let columns = (0..<Int(cmark_gfm_extensions_get_table_columns(node))).map { index -> PresentationIntent.TableColumn in
                switch alignments?[index] {
                case UInt8(ascii: "c"): return .init(alignment: .center)
                case UInt8(ascii: "r"): return .init(alignment: .right)
                default: return .init(alignment: .left)
                }
            }
            pushBlock(.table(columns: columns), attributes: attributes, textBlock: false)
        case "table_header":
            pushBlock(.tableHeaderRow, attributes: attributes, textBlock: false)
        case "table_row":
            stack[stack.count - 1].counter += 1
            pushBlock(.tableRow(rowIndex: stack[stack.count - 1].counter), attributes: attributes, textBlock: false)
        case "table_cell":
            let column = stack[stack.count - 1].counter
            stack[stack.count - 1].counter += 1
            pushBlock(.tableCell(columnIndex: column), attributes: attributes, textBlock: true)

        // Inline containers
        case "emph":
            add(.emphasized)
            stack.append(Frame(attributes: attributes))
        case "strong":
            add(.stronglyEmphasized)
            stack.append(Frame(attributes: attributes))
        case "strikethrough":
            add(.strikethrough)
            stack.append(Frame(attributes: attributes))
        case "link":
            attributes.link = try url(of: node)
            stack.append(Frame(attributes: attributes))
        case "image":
            attributes.imageURL = try url(of: node)
            stack.append(Frame(attributes: attributes))
        case "attribute":
            if options.allowsExtendedAttributes {
                attributes.merge(try extendedAttributes(Self.string(cmark_node_get_attributes(node))))
            }
            stack.append(Frame(attributes: attributes))
        default:
            stack.append(Frame(attributes: attributes))
        }
    }

    /// Opens a block. A text block (paragraph, header, table cell) also gives its content the presentation intent.
    mutating func pushBlock(_ kind: PresentationIntent.Kind, attributes: AttributeContainer, textBlock: Bool) {
        var attributes = attributes
        let intent = makeIntent(kind)
        if textBlock {
            attributes.presentationIntent = presentationIntent(adding: intent)
        }
        stack.append(Frame(attributes: attributes, intent: intent))
    }

    mutating func makeIntent(_ kind: PresentationIntent.Kind) -> PresentationIntent.IntentType? {
        guard options.interpretedSyntax == .full else { return nil }
        defer { nextIdentity += 1 }
        return PresentationIntent.IntentType(kind: kind, identity: nextIdentity)
    }

    /// `innermost` inside every open block, innermost first; nil when there is none.
    func presentationIntent(adding innermost: PresentationIntent.IntentType?) -> PresentationIntent? {
        let types = (innermost.map { [$0] } ?? []) + stack.reversed().compactMap(\.intent)
        return types.isEmpty ? nil : PresentationIntent(types: types)
    }

    mutating func append(_ text: String, attributes: AttributeContainer, node: Node) {
        var attributes = attributes
        // cmark gives soft and hard breaks no position (line 0), so they get no source position attribute.
        if options.appliesSourcePositionAttributes && cmark_node_get_start_line(node) != 0 {
            attributes.markdownSourcePosition = AttributedString.MarkdownSourcePosition(
                startLine: Int(cmark_node_get_start_line(node)), startColumn: Int(cmark_node_get_start_column(node)),
                endLine: Int(cmark_node_get_end_line(node)), endColumn: Int(cmark_node_get_end_column(node)))
        }
        result.append(AttributedString(text, attributes: attributes))
    }

    /// The link or image destination, percent-encoded where cmark left it raw, resolved against the base URL.
    /// An empty destination has no URL.
    func url(of node: Node) throws -> URL? {
        let destination = Self.string(cmark_node_get_url(node))
        if destination.isEmpty { return nil }
        let encoded = destination.addingPercentEncoding(withAllowedCharacters: Self.urlCharacters) ?? destination
        if let url = URL(string: encoded, relativeTo: baseURL) { return url }
        return try recover(Self.error("Invalid link destination '\(destination)'"))
    }

    func extendedAttributes(_ list: String) throws -> AttributeContainer {
        do {
            let decoder = JSONDecoder()
            decoder.userInfo[_markdownKeysUserInfoKey] = markdownKeys
            let json = try _jsonObject(fromExtendedAttributes: list)
            return try decoder.decode(_ExtendedAttributes.self, from: Data(json.utf8)).container
        } catch {
            return try recover(Self.error("Invalid extended attributes '\(list)': \(error)")) ?? AttributeContainer()
        }
    }

    /// Throws under `.throwError`; otherwise drops what failed and parsing goes on.
    func recover<T>(_ error: CocoaError) throws -> T? {
        if options.failurePolicy == .throwError { throw error }
        return nil
    }

    static func type(of node: Node) -> String {
        string(cmark_node_get_type_string(node))
    }

    static func string(_ pointer: UnsafePointer<CChar>?) -> String {
        pointer.map { String(cString: $0) } ?? ""
    }
}

// MARK: Extended attributes

private let _markdownKeysUserInfoKey = CodingUserInfoKey(rawValue: "Foundation.MarkdownDecodableAttributedStringKeys")!

/// The scope's `MarkdownDecodableAttributedStringKey`s by Markdown name, including nested scopes'. swift-foundation
/// only gathers these under FOUNDATION_FRAMEWORK, so this walks the scope's stored properties itself.
private func _markdownDecodableKeys(in scope: Any.Type) -> [String : any MarkdownDecodableAttributedStringKey.Type] {
    var keys: [String : any MarkdownDecodableAttributedStringKey.Type] = [:]
    _forEachField(of: scope, options: .ignoreUnknown) { _, _, type, _ in
        if let key = type as? any MarkdownDecodableAttributedStringKey.Type {
            keys[key.markdownName] = key
        } else if let nested = type as? any AttributeScope.Type {
            keys.merge(_markdownDecodableKeys(in: nested)) { _, new in new }
        }
        return true
    }
    return keys
}

private struct _ExtendedAttributes : Decodable {
    struct Key : CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    var container = AttributeContainer()

    init(from decoder: any Decoder) throws {
        let keys = decoder.userInfo[_markdownKeysUserInfoKey] as! [String : any MarkdownDecodableAttributedStringKey.Type]
        let values = try decoder.container(keyedBy: Key.self)
        for key in values.allKeys {
            guard let type = keys[key.stringValue] else { continue }
            try Self.decode(type, from: values.superDecoder(forKey: key), into: &container)
        }
    }

    private static func decode<K : MarkdownDecodableAttributedStringKey>(_ key: K.Type, from decoder: any Decoder, into container: inout AttributeContainer) throws {
        container[K.self] = try K.decodeMarkdown(from: decoder)
    }
}

/// Rewrites an extended-attribute list (`key: 'value', other: 2`, JSON5 without braces) as strict JSON for
/// JSONDecoder, which rejects any other JSON5 extension.
private func _jsonObject(fromExtendedAttributes list: String) throws -> String {
    let scalars = Array(list.unicodeScalars)
    var json = String.UnicodeScalarView()
    json.append("{")
    func isIdentifierStart(_ c: Unicode.Scalar) -> Bool { c == "_" || c == "$" || c.properties.isAlphabetic }
    func nextNonWhitespace(after index: Int) -> Unicode.Scalar? {
        scalars[(index + 1)...].first { !$0.properties.isWhitespace }
    }
    var i = 0
    while i < scalars.count {
        let c = scalars[i]
        if c == "\"" || c == "'" {
            json.append("\"")
            i += 1
            while i < scalars.count && scalars[i] != c {
                if scalars[i] == "\\" && i + 1 < scalars.count {
                    if scalars[i + 1] != "'" { json.append("\\") }
                    json.append(scalars[i + 1])
                    i += 2
                    continue
                }
                if scalars[i] == "\"" { json.append("\\") }
                json.append(scalars[i])
                i += 1
            }
            guard i < scalars.count else { throw _MarkdownTranslator.error("Unterminated string in extended attributes '\(list)'") }
            json.append("\"")
            i += 1
        } else if isIdentifierStart(c) {
            var end = i
            while end < scalars.count && (isIdentifierStart(scalars[end]) || scalars[end].properties.numericType != nil) { end += 1 }
            let isKey = nextNonWhitespace(after: end - 1) == ":"
            if isKey { json.append("\"") }
            json.append(contentsOf: scalars[i..<end])
            if isKey { json.append("\"") }
            i = end
        } else if c == "," {
            let next = nextNonWhitespace(after: i)
            if next != nil && next != "}" && next != "]" { json.append(",") }
            i += 1
        } else {
            json.append(c)
            i += 1
        }
    }
    json.append("}")
    return String(json)
}
