# Overlays for SDK frameworks

Built by `sdk-frameworks.cmake` (included from the parent CMakeLists.txt): IOKit, CoreAudio and Compression.

Sources: `apple/swift` tag `swift-5.2.2-RELEASE` (d66af16429153d81a8f5791a6da9d9b3d4b61bc7),
`stdlib/public/Darwin/<Framework>`, unmodified. Swift 5.3 and later removed these directories from apple/swift, so
5.2.2 is the last open-source version; `Dispatch`, `Foundation` and the other base overlays come from 5.4 as
described in README.md. Compression needs the SDK's `Compression` Clang module.

The other Swift 5.2.2 overlays are still shipped as prebuilt binaries; their sources do not compile against
Darling's framework headers yet.
