// AttributedString(markdown:) through the Foundation overlay's swift-cmark translation, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

/// Each run's text with its inline intent, e.g. ["Some ": [], "em": [.emphasized]].
func inlineRuns(_ string: AttributedString) -> [(String, InlinePresentationIntent)] {
    string.runs[\.inlinePresentationIntent].map { (String(string[$0.1].characters), $0.0 ?? []) }
}

func blockRuns(_ string: AttributedString) -> [(String, [PresentationIntent.Kind], [Int])] {
    string.runs[\.presentationIntent].map {
        (String(string[$0.1].characters), $0.0?.components.map(\.kind) ?? [], $0.0?.components.map(\.identity) ?? [])
    }
}

do {
    let s = try AttributedString(markdown: "Some *em*, **strong**, ***both***, `code` and ~~gone~~.")
    check(String(s.characters) == "Some em, strong, both, code and gone.", "markup is removed (\(String(s.characters)))")
    let runs = inlineRuns(s)
    let expected: [(String, InlinePresentationIntent)] = [
        ("Some ", []), ("em", .emphasized), (", ", []), ("strong", .stronglyEmphasized), (", ", []),
        ("both", [.emphasized, .stronglyEmphasized]), (", ", []), ("code", .code), (" and ", []),
        ("gone", .strikethrough), (".", []),
    ]
    check(runs.count == expected.count && zip(runs, expected).allSatisfy { $0.0 == $1.0 && $0.1 == $1.1 },
          "emphasis, strong, code and strikethrough intents (\(runs))")

    let links = try AttributedString(markdown: "[Swift](https://swift.org) and [guide](guide.html) ![logo](img/logo.png)",
                                     baseURL: URL(string: "https://example.com/docs/"))
    let linkRuns = links.runs[\.link].compactMap { url, range in url.map { (String(links[range].characters), $0) } }
    check(linkRuns.count == 2 && linkRuns[0].0 == "Swift" && linkRuns[0].1.absoluteString == "https://swift.org",
          "absolute link")
    check(linkRuns.count == 2 && linkRuns[1].0 == "guide" && linkRuns[1].1.absoluteString == "https://example.com/docs/guide.html",
          "relative link resolved against baseURL (\(linkRuns.map { $0.1.absoluteString }))")
    let image = links.runs[\.imageURL].compactMap { url, range in url.map { (String(links[range].characters), $0.absoluteString) } }
    check(image.count == 1 && image[0].0 == "logo" && image[0].1 == "https://example.com/docs/img/logo.png",
          "image alt text carries imageURL (\(image))")
    let autolink = try AttributedString(markdown: "Visit https://example.org now")
    check(autolink.runs[\.link].contains { $0.0?.absoluteString == "https://example.org" }, "GFM autolink")

    let doc = try AttributedString(markdown: """
        # Title

        First line
        second line

        - one
        - two

        3) three
        4) four
        """)
    check(String(doc.characters) == "TitleFirst line second lineonetwothreefour",
          "blocks are not separated by characters, a soft break is a space (\(String(doc.characters)))")
    let blocks = blockRuns(doc)
    check(blocks.count == 6, "one run per block (\(blocks.count))")
    if blocks.count == 6 {
        check(blocks[0].1 == [.header(level: 1)] && blocks[0].2 == [1], "header intent")
        check(blocks[1].1 == [.paragraph] && blocks[1].2 == [2], "paragraph intent")
        check(blocks[2].0 == "one" && blocks[2].1 == [.paragraph, .listItem(ordinal: 1), .unorderedList] && blocks[2].2 == [5, 4, 3],
              "unordered list item, innermost first (\(blocks[2]))")
        check(blocks[3].1 == [.paragraph, .listItem(ordinal: 2), .unorderedList] && blocks[3].2 == [7, 6, 3], "second item shares the list identity")
        check(blocks[4].1 == [.paragraph, .listItem(ordinal: 3), .orderedList] && blocks[5].1 == [.paragraph, .listItem(ordinal: 4), .orderedList],
              "ordered list ordinals follow the start number (\(blocks[4].1), \(blocks[5].1))")
    }
    check(doc.runs[\.inlinePresentationIntent].contains { $0.0 == .softBreak && String(doc[$0.1].characters) == " " }, "soft break intent")
    let delimiters = doc.runs[\.listItemDelimiter].compactMap { delimiter, range in delimiter.map { (String(doc[range].characters), $0) } }
    check(delimiters.map(\.0) == ["onetwo", "threefour"] && delimiters.map(\.1) == ["-", ")"], "list item delimiters (\(delimiters))")
    if let item = doc.runs[\.presentationIntent].first(where: { String(doc[$0.1].characters) == "one" })?.0 {
        check(item.isValid && item.indentationLevel == 1 && item.count == 3, "isValid, indentationLevel and count")
    }

    let blocks2 = try AttributedString(markdown: """
        > quoted

        ```swift
        let x = 1
        ```

        | a | b |
        |:-:|--:|
        | 1 | 2 |
        """)
    let b2 = blockRuns(blocks2)
    check(b2.count == 6, "quote, code block, header cells and body cells (\(b2.map(\.0)))")
    if b2.count == 6 {
        check(b2[0].1 == [.paragraph, .blockQuote], "block quote")
        check(b2[1].0 == "let x = 1\n" && b2[1].1 == [.codeBlock(languageHint: "swift")], "code block with language hint (\(b2[1]))")
        let columns = [PresentationIntent.TableColumn(alignment: .center), PresentationIntent.TableColumn(alignment: .right)]
        check(b2[2].0 == "a" && b2[2].1 == [.tableCell(columnIndex: 0), .tableHeaderRow, .table(columns: columns)], "table header cell (\(b2[2].1))")
        check(b2[5].0 == "2" && b2[5].1 == [.tableCell(columnIndex: 1), .tableRow(rowIndex: 1), .table(columns: columns)], "table body cell (\(b2[5].1))")
    }

    check(try AttributedString(markdown: "").characters.isEmpty, "empty input")
    let nested = try AttributedString(markdown: "- a\n  - b\n  - c\n- d")
    let nestedBlocks = blockRuns(nested)
    check(nestedBlocks.map(\.0) == ["a", "b", "c", "d"], "nested list text (\(nestedBlocks.map(\.0)))")
    if nestedBlocks.count == 4 {
        check(nestedBlocks[1].1 == [.paragraph, .listItem(ordinal: 1), .unorderedList, .listItem(ordinal: 1), .unorderedList]
                && nestedBlocks[2].1 == [.paragraph, .listItem(ordinal: 2), .unorderedList, .listItem(ordinal: 1), .unorderedList]
                && nestedBlocks[3].1 == [.paragraph, .listItem(ordinal: 2), .unorderedList],
              "nested list ordinals restart per list (\(nestedBlocks.map(\.1)))")
        check(nestedBlocks[1].2[2] == nestedBlocks[2].2[2] && nestedBlocks[1].2[2] != nestedBlocks[0].2[2], "nested list identities")
        check(nestedBlocks[1].1.count == 5, "nested indentation (\(nestedBlocks[1].1.count))")
    }
    let ragged = try AttributedString(markdown: "| a | b |\n|---|---|\n| 1 |\n| | 4 |")
    let raggedBlocks = blockRuns(ragged)
    let leftColumns = [PresentationIntent.TableColumn(alignment: .left), PresentationIntent.TableColumn(alignment: .left)]
    check(raggedBlocks.map(\.0) == ["a", "b", "1", "4"], "missing and empty cells add no text (\(raggedBlocks.map(\.0)))")
    check(raggedBlocks.last?.1 == [.tableCell(columnIndex: 1), .tableRow(rowIndex: 2), .table(columns: leftColumns)],
          "unaligned columns are left aligned (\(String(describing: raggedBlocks.last?.1)))")
    let unicodeLink = try AttributedString(markdown: "[x](<https://example.com/wiki/Ä b>) [y]()", baseURL: URL(string: "https://example.com/"))
    let unicodeURLs = unicodeLink.runs[\.link].compactMap { $0.0?.absoluteString }
    check(unicodeURLs == ["https://example.com/wiki/%C3%84%20b"], "non-ASCII destination is percent-encoded, an empty one has no link (\(unicodeURLs))")
    let depth = 100_000
    let deep = try AttributedString(markdown: String(repeating: ">", count: depth) + " deep")
    let deepIntent = deep.runs[\.presentationIntent].first?.0
    check(String(deep.characters) == "deep" && deepIntent?.count == depth + 1 && deepIntent?.indentationLevel == depth,
          "\(depth) nested block quotes (\(String(describing: deepIntent?.count)))")

    let inline = try AttributedString(markdown: "# Not a *heading*\n- nor a list", options: .init(interpretedSyntax: .inlineOnly))
    check(String(inline.characters) == "# Not a heading\n- nor a list", "inlineOnly keeps block syntax and newlines as text (\(String(inline.characters)))")
    check(inline.runs[\.presentationIntent].allSatisfy { $0.0 == nil }, "inlineOnly sets no presentation intent")
    check(inlineRuns(inline).contains { $0.0 == "heading" && $0.1 == .emphasized }, "inlineOnly still parses emphasis")

    // OpenSwiftUI's Text+Localized check for styled keys.
    let options = AttributedString.MarkdownParsingOptions(allowsExtendedAttributes: false, interpretedSyntax: .inlineOnlyPreservingWhitespace, failurePolicy: .throwError)
    let preserved = try AttributedString(markdown: "  Hello\n**world**  \n", options: options, baseURL: nil)
    check(String(preserved.characters) == "  Hello\nworld  \n", "inlineOnlyPreservingWhitespace keeps spaces and newlines (\(String(preserved.characters).debugDescription))")
    check(preserved.runs[AttributeScopes.FoundationAttributes.InlinePresentationIntentAttribute.self, AttributeScopes.FoundationAttributes.LinkAttribute.self]
            .contains { intent, link, _ in intent != nil || link != nil }, "styled runs found by attribute types")
    check(try AttributedString(markdown: "plain", options: options).runs.count == 1, "plain text is one unstyled run")

    let positioned = try AttributedString(markdown: "This is *emphasized*.", options: .init(appliesSourcePositionAttributes: true))
    let position = positioned.runs[\.markdownSourcePosition].first { String(positioned[$0.1].characters) == "emphasized" }?.0
    check(position == AttributedString.MarkdownSourcePosition(startLine: 1, startColumn: 10, endLine: 1, endColumn: 19),
          "source position omits the markup (\(String(describing: position)))")
    let broken = try AttributedString(markdown: "a\nb", options: .init(appliesSourcePositionAttributes: true))
    let breakPositions = broken.runs[\.markdownSourcePosition].map { (String(broken[$0.1].characters), $0.0) }
    check(breakPositions.map(\.0) == ["a", " ", "b"] && breakPositions[1].1 == nil && breakPositions[2].1?.startLine == 2,
          "a soft break has no source position (\(breakPositions))")
    check(try AttributedString(markdown: "x").runs[\.markdownSourcePosition].allSatisfy { $0.0 == nil }, "no source positions by default")

    let french = try AttributedString(markdown: "Bonjour *le monde*", options: .init(languageCode: "fr"))
    check(french.runs[\.languageIdentifier].allSatisfy { $0.0 == "fr" }, "languageCode sets languageIdentifier")

    let data = try AttributedString(markdown: Data("**bold**".utf8))
    check(inlineRuns(data).map(\.1) == [.stronglyEmphasized], "Data input")
    let invalid = Data([0x61, 0xff, 0x62])
    check((try? AttributedString(markdown: invalid)) == nil, "invalid UTF-8 throws")
    let repaired = try AttributedString(markdown: invalid, options: .init(failurePolicy: .returnPartiallyParsedIfPossible))
    check(String(repaired.characters) == "a\u{FFFD}b", "returnPartiallyParsedIfPossible repairs invalid UTF-8")

    let directory = NSTemporaryDirectory() as NSString
    let file = URL(fileURLWithPath: directory.appendingPathComponent("attributed-string-markdown-test.md"))
    try Data("See [notes](notes.md)".utf8).write(to: file)
    let fromFile = try AttributedString(contentsOf: file)
    let notes = URL(fileURLWithPath: directory.appendingPathComponent("notes.md"))
    check(fromFile.runs[\.link].contains { $0.0?.absoluteURL == notes }, "contentsOf resolves links against the file")
    try? FileManager.default.removeItem(at: file)

    let intent = PresentationIntent(.listItem(ordinal: 1), identity: 2, parent: PresentationIntent(.orderedList, identity: 1))
    let json = String(decoding: try JSONEncoder().encode(intent), as: UTF8.self)
    check(json == #"{"components":[{"kind":["listItem",1],"identity":2},{"kind":["orderedList"],"identity":1}]}"#
            || json == #"{"components":[{"identity":2,"kind":["listItem",1]},{"identity":1,"kind":["orderedList"]}]}"#,
          "PresentationIntent encodes kinds as [name, value] (\(json))")
    check(try JSONDecoder().decode(PresentationIntent.self, from: Data(json.utf8)) == intent, "PresentationIntent Codable round trip")
    check(!PresentationIntent(.listItem(ordinal: 1), identity: 1).isValid, "a list item outside a list is not valid")
} catch {
    check(false, "unexpected error \(error)")
}

// Extended attributes, decoded through a scope's MarkdownDecodableAttributedStringKey.
enum RainbowAttribute : CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    typealias Value = String
    static let name = "rainbow"
}
enum CountAttribute : CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    typealias Value = Int
    static let name = "count"
}
struct TestAttributes : AttributeScope {
    let rainbow: RainbowAttribute
    let count: CountAttribute
    let foundation: AttributeScopes.FoundationAttributes
}

do {
    let source = "a ^[bright](rainbow: 'extreme', count: 3,) b"
    let extended = try AttributedString(markdown: source, including: TestAttributes.self, options: .init(allowsExtendedAttributes: true))
    check(String(extended.characters) == "a bright b", "extended attribute text")
    let run = extended.runs.first { String(extended[$0.range].characters) == "bright" }
    check(run?[RainbowAttribute.self] == "extreme" && run?[CountAttribute.self] == 3, "extended attribute values decoded (JSON5 keys, quotes, trailing comma)")
    let ignored = try AttributedString(markdown: source, including: TestAttributes.self)
    check(String(ignored.characters) == "a bright b" && ignored.runs.count == 1, "extended attributes need allowsExtendedAttributes")
    let bad = "^[x](rainbow: 'unterminated)"
    do {
        _ = try AttributedString(markdown: bad, including: TestAttributes.self, options: .init(allowsExtendedAttributes: true))
        check(false, "malformed extended attributes throw")
    } catch let error as CocoaError {
        check(error.code.rawValue == NSFormattingError, "malformed extended attributes throw NSFormattingError")
    }
    let partial = try AttributedString(markdown: bad, including: TestAttributes.self,
                                       options: .init(allowsExtendedAttributes: true, failurePolicy: .returnPartiallyParsedIfPossible))
    check(String(partial.characters) == "x" && partial.runs.count == 1, "returnPartiallyParsedIfPossible keeps the text")
} catch {
    check(false, "unexpected error \(error)")
}

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
