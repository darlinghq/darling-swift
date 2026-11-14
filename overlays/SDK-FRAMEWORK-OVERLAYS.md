# Overlays for SDK frameworks

Built by `sdk-frameworks.cmake` (included from the parent CMakeLists.txt): IOKit, CoreAudio, Compression and CoreText.

Sources: `apple/swift` tag `swift-5.2.2-RELEASE` (d66af16429153d81a8f5791a6da9d9b3d4b61bc7),
`stdlib/public/Darwin/<Framework>`, unmodified. Swift 5.3 and later removed these directories from apple/swift, so
5.2.2 is the last open-source version; `Dispatch`, `Foundation` and the other base overlays come from 5.4 as
described in README.md. Compression needs the SDK's `Compression` Clang module.

The other Swift 5.2.2 overlays are still shipped as prebuilt binaries; their sources do not compile against
Darling's framework headers yet.

`CoreText` is not from apple/swift either: `CoreText/CoreText.swift` is written for Darling from the public API. It declares `AttributedString.AdaptiveImageGlyph` (image content, equality, hashing, Codable) and the package-access conversions to and from `CTAdaptiveImageGlyph` under the mangled names macOS exports from CoreText (checked with the SDK's CoreText.tbd: 18 of the 24 AdaptiveImageGlyph names are defined). `contentIdentifier`, `contentDescription` and `contentType` are not included because the content format they read is not documented; programs that bind them fail at load. The class `CTAdaptiveImageGlyph` itself is CoreText's (darling-cocotron) and is declared for Swift by `CoreText/shims`. `tests/coretext_adaptive_image_glyph.swift` covers it. macOS exports these symbols from CoreText itself, so a CoreText that does not re-export or contain this library does not make them reachable through its install name.
