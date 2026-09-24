//===----------------------------------------------------------------------===//
//
// This source file is part of the darling-swift project.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
//===----------------------------------------------------------------------===//

// PresentationIntent, written for Darling from Apple's public API documentation and the declarations in the
// macOS SDK's Foundation.swiftinterface. swift-foundation does not ship it (it is part of the Markdown support
// tracked by swift-foundation issue #44).

/// The block structure a run of attributed text belongs to, innermost block first.
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public struct PresentationIntent : Hashable, Codable, CustomDebugStringConvertible, Sendable {
    public var components: [IntentType]

    public var count: Int {
        components.count
    }

    public var debugDescription: String {
        "[" + components.map(\.debugDescription).joined(separator: ", ") + "]"
    }

    public enum Kind : Hashable, Codable, CustomDebugStringConvertible, Sendable {
        case paragraph
        case header(level: Int)
        case orderedList
        case unorderedList
        case listItem(ordinal: Int)
        case codeBlock(languageHint: String?)
        case blockQuote
        case thematicBreak
        case table(columns: [TableColumn])
        case tableHeaderRow
        case tableRow(rowIndex: Int)
        case tableCell(columnIndex: Int)

        public var debugDescription: String {
            switch self {
            case .paragraph: return "paragraph"
            case .header(let level): return "header \(level)"
            case .orderedList: return "orderedList"
            case .unorderedList: return "unorderedList"
            case .listItem(let ordinal): return "listItem \(ordinal)"
            case .codeBlock(let hint): return hint.map { "codeBlock '\($0)'" } ?? "codeBlock"
            case .blockQuote: return "blockQuote"
            case .thematicBreak: return "thematicBreak"
            case .table(let columns): return "table \(columns.map { "\($0.alignment)" })"
            case .tableHeaderRow: return "tableHeaderRow"
            case .tableRow(let index): return "tableRow \(index)"
            case .tableCell(let index): return "tableCell \(index)"
            }
        }

        // An unkeyed container holding the case name followed by its associated value, e.g. ["header", 1].
        public init(from decoder: any Decoder) throws {
            var container = try decoder.unkeyedContainer()
            let name = try container.decode(String.self)
            switch name {
            case "paragraph": self = .paragraph
            case "header": self = .header(level: try container.decode(Int.self))
            case "orderedList": self = .orderedList
            case "unorderedList": self = .unorderedList
            case "listItem": self = .listItem(ordinal: try container.decode(Int.self))
            case "codeBlock":
                self = .codeBlock(languageHint: try container.decodeIfPresent(String.self))
            case "blockQuote": self = .blockQuote
            case "thematicBreak": self = .thematicBreak
            case "table": self = .table(columns: try container.decode([TableColumn].self))
            case "tableHeaderRow": self = .tableHeaderRow
            case "tableRow": self = .tableRow(rowIndex: try container.decode(Int.self))
            case "tableCell": self = .tableCell(columnIndex: try container.decode(Int.self))
            default:
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown presentation intent kind '\(name)'")
            }
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.unkeyedContainer()
            switch self {
            case .paragraph: try container.encode("paragraph")
            case .header(let level): try container.encode("header"); try container.encode(level)
            case .orderedList: try container.encode("orderedList")
            case .unorderedList: try container.encode("unorderedList")
            case .listItem(let ordinal): try container.encode("listItem"); try container.encode(ordinal)
            case .codeBlock(let hint):
                try container.encode("codeBlock")
                if let hint { try container.encode(hint) }
            case .blockQuote: try container.encode("blockQuote")
            case .thematicBreak: try container.encode("thematicBreak")
            case .table(let columns): try container.encode("table"); try container.encode(columns)
            case .tableHeaderRow: try container.encode("tableHeaderRow")
            case .tableRow(let index): try container.encode("tableRow"); try container.encode(index)
            case .tableCell(let index): try container.encode("tableCell"); try container.encode(index)
            }
        }
    }

    public struct TableColumn : Hashable, Codable, Sendable {
        public enum Alignment : Int, Hashable, Codable, Sendable {
            case left
            case center
            case right
        }

        public var alignment: Alignment

        public init(alignment: Alignment) {
            self.alignment = alignment
        }
    }

    /// One block: its kind and an identity shared by every run in that block.
    public struct IntentType : Hashable, Codable, CustomDebugStringConvertible, Sendable {
        public var kind: Kind
        public var identity: Int

        internal init(kind: Kind, identity: Int) {
            self.kind = kind
            self.identity = identity
        }

        public var debugDescription: String {
            "\(kind.debugDescription) (id \(identity))"
        }
    }

    public init(_ kind: Kind, identity: Int, parent: PresentationIntent? = nil) {
        components = [IntentType(kind: kind, identity: identity)] + (parent?.components ?? [])
    }

    public init(types: [IntentType]) {
        components = types
    }

    /// Whether the identities are unique and every list item, table row and table cell sits directly inside the
    /// block kind that contains it.
    public var isValid: Bool {
        guard Set(components.map(\.identity)).count == components.count else { return false }
        for (index, component) in components.enumerated() {
            let parent = index + 1 < components.count ? components[index + 1].kind : nil
            switch (component.kind, parent) {
            case (.listItem, .orderedList?), (.listItem, .unorderedList?),
                 (.tableHeaderRow, .table?), (.tableRow, .table?),
                 (.tableCell, .tableHeaderRow?), (.tableCell, .tableRow?):
                break
            case (.listItem, _), (.tableHeaderRow, _), (.tableRow, _), (.tableCell, _):
                return false
            default:
                break
            }
        }
        return true
    }

    /// The number of lists and block quotes the innermost block is nested in.
    public var indentationLevel: Int {
        components.reduce(0) { level, component in
            switch component.kind {
            case .orderedList, .unorderedList, .blockQuote: return level + 1
            default: return level
            }
        }
    }
}
