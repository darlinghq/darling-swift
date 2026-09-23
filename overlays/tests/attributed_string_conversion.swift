// AttributedString / AttributeContainer <-> NSAttributedString / [NSAttributedString.Key: Any] conversions, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

enum ShoutAttribute: AttributedStringKey {
    typealias Value = Int
    static let name = "DarlingTestShout"
}

enum MoodAttribute: ObjectiveCConvertibleAttributedStringKey {
    enum Mood: String, Hashable { case calm, loud }
    typealias Value = Mood
    typealias ObjectiveCValue = NSString
    static let name = "DarlingTestMood"
}

enum LevelAttribute: ObjectiveCConvertibleAttributedStringKey {
    enum Level: Int, Hashable { case low = 1, high = 2 }
    typealias Value = Level
    typealias ObjectiveCValue = NSNumber
    static let name = "DarlingTestLevel"
}

struct TestAttributes: AttributeScope {
    let shout: ShoutAttribute
    let mood: MoodAttribute
    let level: LevelAttribute
    let foundation: AttributeScopes.FoundationAttributes
}

extension AttributeScopes {
    var test: TestAttributes.Type { TestAttributes.self }
}

let url = URL(string: "https://example.com/a")!
// Darling's Foundation headers declare neither key constant (AppKit declares NSLinkAttributeName on macOS).
let linkKey = NSAttributedString.Key("NSLink")
let delimiterKey = NSAttributedString.Key("NSListItemDelimiter")
let dict: [NSAttributedString.Key: Any] = [
    linkKey: NSURL(string: "https://example.com/a")!,
    .languageIdentifier: "fr",
    .inlinePresentationIntent: NSNumber(value: InlinePresentationIntent([.emphasized, .code]).rawValue),
    NSAttributedString.Key("NotAnAttribute"): 42,
]

// Dictionary -> AttributeContainer with the default (Foundation) table: unknown keys are dropped.
let container = AttributeContainer(dict)
check(container.link == url, "link from NSURL")
check(container.languageIdentifier == "fr", "languageIdentifier")
check(container.inlinePresentationIntent == [.emphasized, .code], "inlinePresentationIntent from NSNumber")
check(AttributeContainer([linkKey: "https://example.com/a" as NSString]).link == url, "link from NSString")

// AttributeContainer -> Dictionary produces the Objective-C values.
let back = [NSAttributedString.Key: Any](container)
check(back.count == 3, "dictionary has the three Foundation attributes (\(back.keys.map(\.rawValue).sorted()))")
check((back[linkKey] as? NSURL).map { $0 as URL } == url, "link converts to NSURL")
check((back[.inlinePresentationIntent] as? NSNumber).map { UInt(truncating: $0) } == 5, "intent converts to NSNumber")
check((back[.languageIdentifier] as? String) == "fr", "language converts to a string")

// The non-throwing initializer drops values that fail to convert; the scoped one throws.
let bad: [NSAttributedString.Key: Any] = [.inlinePresentationIntent: "not a number" as NSString, .languageIdentifier: "de"]
let dropped = AttributeContainer(bad)
check(dropped.inlinePresentationIntent == nil && dropped.languageIdentifier == "de", "bad value dropped, others kept")
do {
    _ = try AttributeContainer(bad, including: \.foundation)
    check(false, "scoped initializer throws on a bad value")
} catch let error as CocoaError {
    check(error.code == .coderInvalidValue, "scoped initializer throws coderInvalidValue")
}
check((try? AttributeContainer([delimiterKey: "ab" as NSString], including: \.foundation)) == nil,
      "list item delimiter must be one character")
check(AttributeContainer([delimiterKey: "-" as NSString]).listItemDelimiter == "-", "list item delimiter converts")

// A custom scope, reached both by key path and by type; its attributes are not in the default table.
let custom: [NSAttributedString.Key: Any] = [NSAttributedString.Key("DarlingTestShout"): 3,
                                             NSAttributedString.Key("DarlingTestMood"): "loud" as NSString,
                                             .languageIdentifier: "es"]
let scoped = try AttributeContainer(custom, including: \.test)
check(scoped[ShoutAttribute.self] == 3 && scoped[MoodAttribute.self] == .loud && scoped.languageIdentifier == "es",
      "custom scope by key path")
check(try AttributeContainer(custom, including: TestAttributes.self) == scoped, "custom scope by type")
check(AttributeContainer(custom)[ShoutAttribute.self] == nil, "default table ignores custom attributes")
let customBack = try [NSAttributedString.Key: Any](scoped, including: \.test)
check((customBack[NSAttributedString.Key("DarlingTestMood")] as? String) == "loud", "custom RawRepresentable converts to NSString")
check((customBack[NSAttributedString.Key("DarlingTestShout")] as? Int) == 3, "plain value passes through")
let levelKey = NSAttributedString.Key("DarlingTestLevel")
let level = try AttributeContainer([levelKey: NSNumber(value: 2)], including: \.test)
check(level[LevelAttribute.self] == .high, "Int RawRepresentable from NSNumber")
check((try [NSAttributedString.Key: Any](level, including: \.test)[levelKey] as? NSNumber).map { Int(truncating: $0) } == 2,
      "Int RawRepresentable converts to NSNumber")
do {
    _ = try AttributeContainer([levelKey: NSNumber(value: 7)], including: \.test)
    check(false, "unknown Int raw value throws")
} catch let error as CocoaError {
    check(error.code == .coderInvalidValue, "unknown Int raw value throws coderInvalidValue")
}

typealias NameComponent = AttributeScopes.FoundationAttributes.PersonNameComponentAttribute
let nameKey = NSAttributedString.Key(NameComponent.name)
let name = AttributeContainer([nameKey: "givenName" as NSString])
check(name.personNameComponent == .givenName, "personNameComponent from NSString")
check(([NSAttributedString.Key: Any](name)[nameKey] as? String) == "givenName", "personNameComponent converts to NSString")

// OpenSwiftUI compares single-attribute containers built from dictionaries.
check(AttributeContainer([.languageIdentifier: "en"]) == AttributeContainer([.languageIdentifier: "en"]), "equal containers")
check(AttributeContainer([.languageIdentifier: "en"]) != AttributeContainer([.languageIdentifier: "de"]), "unequal containers")

// AttributedString <-> NSAttributedString, with a non-BMP character so UTF-16 and UTF-8 offsets differ.
var attributed = AttributedString("a\u{1F600}bc ")
let firstTwo = attributed.startIndex..<attributed.characters.index(attributed.startIndex, offsetBy: 2)
attributed[firstTwo].link = url
attributed[firstTwo].inlinePresentationIntent = .stronglyEmphasized
attributed.characters.append(contentsOf: "tail")
let ns = NSAttributedString(attributed)
check(ns.string == "a\u{1F600}bc tail", "NSAttributedString text")
var range = NSRange(location: 0, length: 0)
let first = ns.attributes(at: 0, effectiveRange: &range)
check(range == NSRange(location: 0, length: 3), "first run covers a + surrogate pair (\(range))")
check((first[linkKey] as? NSURL).map { $0 as URL } == url, "run link")
check((first[.inlinePresentationIntent] as? NSNumber).map { UInt(truncating: $0) } == InlinePresentationIntent.stronglyEmphasized.rawValue, "run intent")
let rest = ns.attributes(at: 3, effectiveRange: &range)
check(rest.isEmpty && range == NSRange(location: 3, length: 7), "second run has no attributes (\(range))")

let roundTrip = AttributedString(ns)
check(roundTrip == attributed, "AttributedString(NSAttributedString) round-trips")
check(try AttributedString(ns, including: \.foundation) == attributed, "scoped round trip")
check(try NSAttributedString(attributed, including: \.foundation).isEqual(to: ns), "scoped NSAttributedString")

let mutable: NSMutableAttributedString = NSMutableAttributedString(string: "xyz")
mutable.addAttribute(NSAttributedString.Key("DarlingTestMood"), value: "calm" as NSString, range: NSRange(location: 1, length: 1))
let fromCustom = try AttributedString(mutable, including: \.test)
check(fromCustom.runs.count == 3 && fromCustom.runs[MoodAttribute.self].map { $0.0 } == [nil, MoodAttribute.Mood.calm, nil], "custom scope runs")
do {
    mutable.addAttribute(NSAttributedString.Key("DarlingTestMood"), value: "furious" as NSString, range: NSRange(location: 0, length: 1))
    _ = try AttributedString(mutable, including: \.test)
    check(false, "invalid raw value throws")
} catch let error as CocoaError {
    check(error.code == .coderInvalidValue, "invalid raw value throws coderInvalidValue")
}

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
