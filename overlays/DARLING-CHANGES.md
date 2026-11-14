# How the Foundation overlay differs from swift-foundation

`libswiftFoundation` is built from three sources:

- the `release/5.4` Darwin Foundation overlay, adapted for Darling (see `README.md`);
- [apple/swift-foundation](https://github.com/swiftlang/swift-foundation) at tag `swift-6.3.3-RELEASE`
  (commit `dbacc67779dc0a41ddc9493acbaa332d76c9fb03`), Apache License v2.0 with the Runtime Library Exception.
  The files listed in `swift-foundation-sources.cmake` are compiled from a checkout exactly as upstream ships
  them. The files this overlay has to change are copies in `Foundation/`, each starting from the upstream file with
  its licence header kept; `LICENSE-swift-foundation.md` and `NOTICE-swift-foundation.txt` apply to them;
- [swiftlang/swift-cmark](https://github.com/swiftlang/swift-cmark) at the same tag (commit
  `924936d0427cb25a61169739a7660230bffa6ea6`), BSD-2-Clause (`LICENSE-swift-cmark.txt`), compiled into the
  overlay with hidden visibility for `AttributedString(markdown:)`.

Every place where a copied swift-foundation file differs from upstream carries a comment starting with `// Darling:`
that says why. To see the difference, diff the file against the checkout, for example
`diff -u <swift-foundation>/Sources/FoundationEssentials/AttributedString/Conversion.swift Foundation/Conversion.swift`.

## Reasons that recur

- **The overlay is built without `FOUNDATION_FRAMEWORK`.** The code written for Apple's Foundation framework that
  talks to `NSAttributedString`, `NSNumber` and the Objective-C runtime is wrapped in `#if FOUNDATION_FRAMEWORK`
  upstream; the copies of `AttributeScope.swift`, `AttributedStringAttribute.swift`,
  `AttributedStringAttributeStorage.swift`, `Conversion.swift` and `FoundationAttributes.swift` enable the parts
  that Darling's Foundation supports (the conversions between `AttributedString` and `NSAttributedString`, the
  Foundation attribute scope) and read scope contents with the standard library's reflection instead of
  `ReflectionInternal`.
- **Darling's ICU is version 66.** `ICU+Enums.swift` omits what ICU 67 and 70 added (the hour-cycle aliases and
  the narrow quarter symbols). `ICUPatternGenerator.swift`, `Decimal+FormatStyle.swift`,
  `Decimal+ParseStrategy.swift`, `Duration+UnitsFormatStyle.swift` and `DateComponents+ISO8601FormatStyle.swift`
  differ by the qualifiers of the module name, by `Calendar.Component` lacking `dayOfYear`, and by the closed
  `Measurement` format style that `Duration.UnitsFormatStyle` stores a width of.
- **Darling-written files.** `FormattingSupport.swift` supplies the `Locale` and `Calendar` internals that
  swift-foundation's formatting code expects over Darling's `NSLocale`, `NSCalendar` and ICU;
  `Date+ComponentsFormatStyle.swift` implements `Date.ComponentsFormatStyle` over ICU's measure formatter;
  `AttributedString+Markdown.swift`, `PresentationIntent.swift` and `AttributedString+Localized.swift`
  implement `AttributedString(markdown:)`, the presentation intents and `AttributedString(localized:)` from the
  public documentation, because swift-foundation does not have them.
- **The ICU shim.** `shims/FoundationICU.h` exposes the libicucore headers as the module `_FoundationICU` that
  swift-foundation imports. A header is admitted only when an overlay source calls into it.
