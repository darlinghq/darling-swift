# Overlays for SDK frameworks

Built by `sdk-frameworks.cmake` (included from the parent CMakeLists.txt): IOKit, CoreAudio, Compression, CoreText and UniformTypeIdentifiers.

Sources: `apple/swift` tag `swift-5.2.2-RELEASE` (d66af16429153d81a8f5791a6da9d9b3d4b61bc7),
`stdlib/public/Darwin/<Framework>`, unmodified. Swift 5.3 and later removed these directories from apple/swift, so
5.2.2 is the last open-source version; `Dispatch`, `Foundation` and the other base overlays come from 5.4 as
described in README.md. Compression needs the SDK's `Compression` Clang module. AppKit needs the AppKit headers, module map and `AppKit.apinotes` of the main repository's cocotron (the Swift names of the nested types, typed enums and refined functions the overlay uses); its sources are the six files of `stdlib/public/Darwin/AppKit`.

The other Swift 5.2.2 overlays are still shipped as prebuilt binaries; their sources do not compile against
Darling's framework headers yet.

`CoreText` is not from apple/swift either: `CoreText/CoreText.swift` is written for Darling from the public API. It declares `AttributedString.AdaptiveImageGlyph` (image content, equality, hashing, Codable) and the package-access conversions to and from `CTAdaptiveImageGlyph` under the mangled names macOS exports from CoreText (checked with the SDK's CoreText.tbd: 18 of the 24 AdaptiveImageGlyph names are defined). `contentIdentifier`, `contentDescription` and `contentType` are not included because the content format they read is not documented; programs that bind them fail at load. The class `CTAdaptiveImageGlyph` itself is CoreText's (darling-cocotron) and is declared for Swift by `CoreText/shims`. `tests/coretext_adaptive_image_glyph.swift` covers it. macOS exports these symbols from CoreText itself, so a CoreText that does not re-export or contain this library does not make them reachable through its install name.

`UniformTypeIdentifiers` is not from apple/swift: `UniformTypeIdentifiers/UniformTypeIdentifiers.swift` is written for Darling from the framework's documented Swift API (UTType, UTTagClass). UTType wraps Darling's Objective-C UTType, which the framework's Clang module and `UniformTypeIdentifiers.apinotes` in the SDK import as `UTTypeReference`. The URL, URLResourceValues (`contentType`), String and NSItemProvider extensions, `referenceAccessoryURL`, `setDefaultHandler(to:completionHandler:)` and the static types whose Objective-C constants Darling does not export yet are not included. `tests/uniform_type_identifiers.swift` covers it.

Network (`overlays/Network`, 12 files) is the same tag's `stdlib/public/Darwin/Network`, unmodified. It also imports
the shim module `_SwiftNetworkOverlayShims` (`overlays/shims/NetworkOverlayShims.h`, see DARLING-CHANGES.md), and it needs
libnetwork's prototypes for the `nw_*` functions and the Network and Security Clang module maps in the SDK. The C side
is still largely stubs in libnetwork, so the Swift types construct and compile but most operations do nothing yet.
