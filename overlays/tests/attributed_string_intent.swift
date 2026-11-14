// InlinePresentationIntent and the Foundation attribute scope's intent/language attributes, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

check(NSAttributedString.Key.inlinePresentationIntent.rawValue == "NSInlinePresentationIntent", "inlinePresentationIntent key")
check(NSAttributedString.Key.languageIdentifier.rawValue == "NSLanguage", "languageIdentifier key")
typealias Intent = AttributeScopes.FoundationAttributes.InlinePresentationIntentAttribute
check(Intent.name == NSAttributedString.Key.inlinePresentationIntent.rawValue, "attribute name matches the key")
check(AttributeScopes.FoundationAttributes.LanguageIdentifierAttribute.name == NSAttributedString.Key.languageIdentifier.rawValue,
      "language attribute name matches the key")

let bits: [(InlinePresentationIntent, UInt)] = [(.emphasized, 1), (.stronglyEmphasized, 2), (.code, 4), (.strikethrough, 32),
                                                (.softBreak, 64), (.lineBreak, 128), (.inlineHTML, 256), (.blockHTML, 512)]
check(bits.allSatisfy { $0.0.rawValue == $0.1 }, "option bit values")

var string = AttributedString("bold code, plain")
let boldCode = string.startIndex..<string.characters.index(string.startIndex, offsetBy: 9)
string[boldCode].inlinePresentationIntent = [.stronglyEmphasized, .code]
string.languageIdentifier = "en-US"
let intents = string.runs[\.inlinePresentationIntent].map { $0.0 }
check(intents == [[.stronglyEmphasized, .code], nil], "runs by inlinePresentationIntent (\(intents))")
check(string.runs[Intent.self, AttributeScopes.FoundationAttributes.LinkAttribute.self].contains { intent, link, _ in
    intent != nil || link != nil
}, "runs by attribute types")
check(string[boldCode].inlinePresentationIntent?.contains(.code) == true, "dynamic member lookup")

let encoded = try JSONEncoder().encode(InlinePresentationIntent([.emphasized, .strikethrough]))
check(String(decoding: encoded, as: UTF8.self) == "33", "Codable encodes the raw value")
let decoded = try JSONDecoder().decode(InlinePresentationIntent.self, from: Data("6".utf8))
check(decoded == [.stronglyEmphasized, .code], "Codable decodes the raw value")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
