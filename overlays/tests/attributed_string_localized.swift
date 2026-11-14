// AttributedString(localized:) and AttributedString interpolation in String.LocalizationValue through the Foundation
// overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

func text(_ s: AttributedString) -> String { String(s.characters) }

/// The inline intent of the first run whose text is `word`.
func intent(of word: String, in s: AttributedString) -> InlinePresentationIntent? {
    s.runs[\.inlinePresentationIntent].first { String(s[$0.1].characters) == word }?.0
}

// The test executable has no Localizable.strings, so the key itself is the Markdown format.
let name = "Ada"
let plain = AttributedString(localized: "Hello **\(name)**, 100% *sure*")
check(text(plain) == "Hello Ada, 100% sure", "key is parsed as Markdown and formatted (\(text(plain)))")
check(intent(of: "Ada", in: plain) == .stronglyEmphasized, "argument takes the attributes of its specifier")
check(intent(of: "sure", in: plain) == .emphasized, "literal Markdown styling")
let command = "ls *.txt"
let code = AttributedString(localized: "Run `\(command)` now")
check(text(code) == "Run ls *.txt now" && intent(of: command, in: code) == .code, "specifier inside a code span (\(text(code)))")
check(plain.runs[\.presentationIntent].allSatisfy { $0.0 == nil }, "no block intents (inline-only syntax)")

let counted = AttributedString(localized: "\(3, specifier: "%lld") of \(name)", options: .applyReplacementIndexAttribute)
let indices = counted.runs[\.replacementIndex].compactMap { r in r.0.map { (String(counted[r.1].characters), $0) } }
check(text(counted) == "3 of Ada" && indices.map(\.0) == ["3", "Ada"] && indices.map(\.1) == [1, 2],
      "applyReplacementIndexAttribute numbers the arguments (\(indices))")

var link = AttributedString(name)
link.link = URL(string: "https://example.com/ada")
let merged = AttributedString(localized: "Hi **\(link)**")
let mergedRun = merged.runs.first { String(merged[$0.range].characters) == name }
check(text(merged) == "Hi Ada" && mergedRun?.link == link.link && mergedRun?.inlinePresentationIntent == .stronglyEmphasized,
      "interpolated AttributedString keeps its link and merges the surrounding bold")
let unmerged = AttributedString(localized: "Hi **\(link, options: .insertAttributesWithoutMerging)**")
let unmergedRun = unmerged.runs.first { String(unmerged[$0.range].characters) == name }
check(unmergedRun?.link == link.link && unmergedRun?.inlinePresentationIntent == nil,
      "insertAttributesWithoutMerging keeps only the argument's own attributes")
check(String(localized: "Hi \(link)") == "Hi Ada", "String(localized:) uses an attributed argument's text")
let prefix = link[link.startIndex..<link.index(link.startIndex, offsetByCharacters: 2)]
check(text(AttributedString(localized: "Hi \(prefix)")) == "Hi Ad", "AttributedSubstring interpolation")

let a: String.LocalizationValue = "Hi \(link)"
let b: String.LocalizationValue = "Hi \(link)"
let c: String.LocalizationValue = "Hi \(AttributedString(name))"
check(a == b && a != c && String.LocalizationValue("x") == "x", "LocalizationValue equality compares arguments")
let r1: LocalizedStringResource = "Welcome \(name)"
let r2: LocalizedStringResource = "Welcome \(name)"
check(r1 == r2 && r1 != LocalizedStringResource("Welcome \(name)", table: "Other"), "LocalizedStringResource equality")

// A bundle with an English strings table, written at run time.
let bundleDirectory = "/tmp/darling-swift-attr-l10n-\(getpid())"
mkdir(bundleDirectory, 0o755)
mkdir(bundleDirectory + "/en.lproj", 0o755)
try? #"<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict><key>CFBundleDevelopmentRegion</key><string>en</string><key>CFBundleIdentifier</key><string>org.darling.attr-l10n-test</string></dict></plist>"#
    .write(to: URL(fileURLWithPath: bundleDirectory + "/Info.plist"), atomically: true, encoding: .utf8)
try? #"""
"Hello %@" = "Bonjour *%@*";
"order %lld %@" = "**%2$@** first, then %1$lld";
"key.title" = "Titre [%lld](https://example.com/t)";
"s %d %f %d %d %f" = "%.*f and %*.*f";
"p %d %f" = "[%2$*1$.1f]";
"o %@" = "%@ and %2$@";
"""#.write(to: URL(fileURLWithPath: bundleDirectory + "/en.lproj/Localizable.strings"), atomically: true, encoding: .utf8)
if let bundle = Bundle(url: URL(fileURLWithPath: bundleDirectory)) {
    let hello = AttributedString(localized: "Hello \(name)", bundle: bundle)
    check(text(hello) == "Bonjour Ada" && intent(of: "Ada", in: hello) == .emphasized,
          "strings table translation with Markdown (\(text(hello)))")
    let order = AttributedString(localized: "order \(5, specifier: "%lld") \(name)", bundle: bundle)
    check(text(order) == "Ada first, then 5" && intent(of: "Ada", in: order) == .stronglyEmphasized,
          "positional specifiers reorder arguments (\(text(order)))")
    let title = AttributedString(localized: "key.title", defaultValue: "Title \(7, specifier: "%lld")", bundle: bundle)
    check(text(title) == "Titre 7" && title.runs.first { String(title[$0.range].characters) == "7" }?.link == URL(string: "https://example.com/t"),
          "defaultValue form uses the table's translation (\(text(title)))")
    let resource = LocalizedStringResource("key.title", defaultValue: "Title \(8, specifier: "%lld")", bundle: .atURL(URL(fileURLWithPath: bundleDirectory)))
    check(text(AttributedString(localized: resource)) == "Titre 8", "LocalizedStringResource form")
    let stars = AttributedString(localized: "s \(Int32(2), specifier: "%d") \(3.14159, specifier: "%f") \(Int32(8), specifier: "%d") \(Int32(1), specifier: "%d") \(2.5, specifier: "%f")", bundle: bundle)
    check(text(stars) == "3.14 and      2.5" && stars.runs[\.inlinePresentationIntent].allSatisfy { $0.0 == nil },
          "`*` widths are not read as emphasis (\(text(stars)))")
    let positional = AttributedString(localized: "p \(Int32(6), specifier: "%d") \(2.5, specifier: "%f")", bundle: bundle)
    check(text(positional) == "[   2.5]", "positional `*` width (\(text(positional)))")
    let outOfRange = AttributedString(localized: "o \(name)", bundle: bundle)
    check(text(outOfRange) == "Ada and %2$@", "a specifier with no argument stays as text (\(text(outOfRange)))")
    let missing = AttributedString(localized: "not.there", defaultValue: "Fallback *\(name)*", bundle: bundle)
    check(text(missing) == "Fallback Ada" && intent(of: "Ada", in: missing) == .emphasized, "a missing key uses the default value")
} else {
    check(false, "test bundle at \(bundleDirectory)")
}

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
