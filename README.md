# Darling Swift

Attention: This repository uses Git LFS!

Files found here come from official Swift releases from Swift.org. They are downloaded and extracted using the `build.sh` script before committing.

The runtime libraries (`libswiftCore`, `libswift_Concurrency`, `libswift_StringProcessing`, `libswiftObservation`, ...) come from the release in `version.txt` and are universal (arm64 and x86_64) binaries.

Swift.org toolchains no longer include the Darwin SDK overlays (`libswiftAppKit`, `libswiftFoundation`, `libswiftObjectiveC`, `libswiftDispatch`, ...). `libswiftDarwin`, `libswiftObjectiveC`, `libswiftCoreFoundation`, `libswiftCoreGraphics`, `libswiftDispatch`, `libswiftFoundation`, `libswiftos` and `libswiftXPC` are built from the sources in `overlays/` by CMake (see `overlays/README.md`), for x86_64 or arm64 like the rest of Darling, and are skipped when the build finds no Swift toolchain. The other overlays still in this repository come from Swift 5.2.2 and are x86_64-only.

`stdlib-modules/` holds the textual module interfaces (`.swiftinterface`, x86_64 and arm64, public and private) of the runtime's Swift modules, taken from the same package. `build.sh` copies every macOS interface the package ships, so newer releases which add modules or private interfaces do not need a list here. The Swift compiler needs these interfaces to build code for macOS against this runtime, because the Linux toolchains have no macOS standard library module. The Swift SDK overlays in this repository are built from source against them by CMake when a Swift toolchain is available.

## Helper dylibs built by CMake

A few small libraries are built from the sources in this directory (`CMakeLists.txt`) instead of being copied from a release:

- `libswift_errno` defines the two `Darwin.errno` accessors over libSystem's `__error()`. Recent macOS SDKs split them out of `libswiftDarwin`, and new Swift runtimes import the getter from this library non-weakly, so it is built even when no Swift toolchain was found and the source-built overlays are skipped.
- `libswift_DarwinFoundation1/2/3`, `libswift_math`, `libswift_signal`, `libswift_stdio`, `libswift_time`, `libswiftsys_time` and `libswiftunistd` contain no code. Recent macOS SDKs split the Darwin overlay across these libraries and binaries bind Darwin symbols to them by library ordinal. Here the whole overlay lives in `libswiftDarwin.dylib`, so each of these libraries only re-exports it, and they are built only together with the overlays (when a Swift toolchain was found).
- `libswiftWebKit` only defines the `__swift_FORCE_LOAD_$_swiftWebKit` marker, so that binaries that link the WebKit overlay load. It exports nothing else.

## License and provenance

- **Runtime libraries:** unmodified binaries from `usr/lib/swift/macosx` in `swift-6.3.3-RELEASE-osx.pkg` from download.swift.org (SHA-256 `ee82e57774d6650f94aa06302435d6f44a055b9411698db8ecb85d9a3bcc91d0`). `libswiftCompatibilitySpan.dylib` is a symlink to `libswiftCore.dylib`, as in the pkg.
- **Module interfaces:** the macOS `.swiftinterface` files in `usr/lib/swift/macosx` of the same package, unmodified, public and private (private interfaces are required for SPIs such as `@_spi(Foundation) import Swift`).
- **Overlays built from `overlays/`:** `libswiftDarwin`, `libswiftObjectiveC`, `libswiftCoreFoundation`, `libswiftCoreGraphics`, `libswiftDispatch`, `libswiftFoundation`, `libswiftos` and `libswiftXPC` are compiled by CMake and are not stored in this repository.
- **Other overlays:** unmodified x86_64 binaries from the Swift 5.2.2 macOS pkg.

Swift is Copyright Apple Inc. and the Swift project authors, and is licensed under the Apache License v2.0 with Runtime Library Exception. `LICENSE.txt` is the copy shipped in the pkg (`usr/share/swift/LICENSE.txt`).
