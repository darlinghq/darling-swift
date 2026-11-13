# Swift SDK overlays built from source

Swift.org toolchains stopped shipping the Darwin SDK overlays, so the copies in this repository were x86_64-only (Swift 5.2.2). The CMake build of this repository builds six of them from source, for the architecture the Darling build produces (x86_64, or arm64 with `TARGET_ARM64`), and installs them in place of the 5.2.2 ones. Four are built from the last open-source Swift sources; `os` and `XPC` were never open source, so they are written from Apple's public API documentation and the imported symbol names (no Apple code).

| Overlay | Sources | Notes |
|---|---|---|
| `libswiftDarwin` | `swiftlang/swift` `release/6.1`, `stdlib/public/Platform` (`Darwin.swift` and `tgmath.swift` pre-expanded with gyb) | Needed at build time by the other overlays: the Clang importer maps C `Boolean` to `Darwin.DarwinBoolean` |
| `libswiftObjectiveC` | `release/5.4`, `stdlib/public/Darwin/ObjectiveC` | Unmodified |
| `libswiftCoreFoundation` | `release/5.4` `CoreFoundation.swift`, plus `CGFloat.swift` from the 5.4 CoreGraphics overlay | Newer SDKs moved `CGFloat` into this overlay; it's declared `@_originallyDefinedIn(module: "CoreGraphics", ...)` so its symbols keep their `CoreGraphics` mangling |
| `libswiftDispatch` | `release/5.4`, `stdlib/public/Darwin/Dispatch` | `Schedulers+DispatchQueue.swift` is dropped (it needs Combine). `Darling+NewerSDK.swift` and a designated `DispatchWorkItem.init(flags:block:)` add APIs from newer SDKs. The `OS_dispatch_queue_serial_executor` class that `Darling+NewerSDK.swift` extends is defined by Darling's libdispatch |
| `libswiftCoreGraphics` | `release/5.4` CoreGraphics overlay members, adapted for Darling's headers (the fork's commits, `overlays/CoreGraphics`) | Re-exports `libswiftCoreFoundation`, which defines `CGFloat` |
| `libswiftFoundation` | `release/5.4` Foundation overlay adapted for Darling, plus AttributedString, FormatStyle protocols and Locale types from `apple/swift-foundation` (tag `swift-6.3.3-RELEASE`, vendored in `overlays/Foundation` with `LICENSE-swift-foundation.md` and `NOTICE-swift-foundation.txt`) | Backed by Darling's Foundation, CoreFoundation and ICU. AttributedString's text storage is `swift-collections` 1.1.6 `RopeModule` and `InternalCollectionsUtilities` (`overlays/Collections`), linked in without exporting their symbols. Partial by design, see below |
| `libswiftos` | Clean-room (`os/os.swift`) | `Logger`, `os_log`, `os_signpost`, `OSSignpostID`, `OSSignposter`, `OSSignpostIntervalState`, `OSAllocatedUnfairLock`, and the `OSLog`/`OSLogType`/`OSSignpostType` extensions. `os_log` encodes arguments into the os_log buffer format and calls `_os_log_impl`. Signposts report as disabled: Darling's libsystem_trace signpost entry points abort |
| `libswiftXPC` | Clean-room (`XPC/XPC.swift`) | `XPCSession`, `XPCDictionary` (copy-on-write, with Bool/String/integer/object/dictionary/array subscripts), `XPCArray` and `XPCRichError`, on top of libxpc's C API |

Sources from the Swift project are licensed under the Apache License v2.0 with Runtime Library Exception. `os/`, `XPC/`, `Dispatch/Darling+NewerSDK.swift`, `Dispatch/include/swift/Runtime/Debug.h` and `tests/` were written for Darling.

## Coverage of what macOS 26 apps import

Measured against every binary in `/System/Applications` of a macOS 26.6.2 install:

- **ObjectiveC:** 14/14 symbols.
- **CoreFoundation:** 15/15, including the `$s12CoreGraphics7CGFloatV…` metadata and conformances.
- **os:** 44/44.
- **XPC:** 21/21.
- **Dispatch:** 94/104. The missing 10 are the Combine `Scheduler` conformance of `DispatchQueue` and its `SchedulerTimeType`/`SchedulerOptions` types (Combine is closed source).

## Building

`CMakeLists.txt` in the parent directory builds the overlays with the Swift toolchain that the main repository's `cmake/swift_toolchain.cmake` finds (`-DSWIFT_TOOLCHAIN=<root>` selects one, `-DSWIFT_TOOLCHAIN=OFF` skips them). Without a toolchain the overlays are skipped and the rest of the build is unaffected. The function `add_darling_swift_library` (main repository, `cmake/darling_swift.cmake`) compiles each overlay with `swiftc -frontend` for `<arch>-apple-macosx26.0` against Darling's source-tree SDK and the module interfaces in `stdlib-modules/`, and links it with Darling's ld64 against Darling's libSystem, libobjc and CoreFoundation. The overlays import each other, so the targets depend on one another in the order Darwin, ObjectiveC and CoreFoundation, Dispatch, then os and XPC.

The toolchain is the Linux Swift release matching `version.txt` (for example `swift-6.3.3-RELEASE-debian12.tar.gz` from download.swift.org); its `swiftc -frontend` cross-compiles to `apple-macosx`. The Darling SDK must contain the Clang module maps and API notes for Darwin, ObjectiveC, Dispatch, os, XPC and CoreFoundation, and the `sys/cdefs.h` default-platform fix. Without that fix, arm64 code links against `$UNIX2003` symbol variants that don't exist. The Dispatch overlay needs the libdispatch with the `OS_dispatch_queue_serial_executor` class.

## Tests

`tests/os_xpc.swift` covers `Logger`, `os_log` with arguments, signpost IDs and intervals, `OSAllocatedUnfairLock` across threads, `XPCDictionary`/`XPCArray` and `XPCSession`. `tests/objc_only.swift` and `tests/objc_cf.swift` cover an NSObject subclass with `@objc` methods and selectors, NSObject `Equatable`/`Hashable`, `autoreleasepool`, `ObjCBool`, CF types as `Hashable` (`_CFObject`), CFString round trips, and CGFloat. Build them for `<arch>-apple-macosx26.0` against these overlays, link with Darling's ld64 (plus `-Xfrontend -disable-objc-attr-requires-foundation-module`, since there is no Foundation Swift overlay), and run them with `darling shell`.

## Foundation coverage

The Foundation overlay is intentionally partial. Against the Swift 5.2.2 `libswiftFoundation` it replaces, 1544 of 4452 exported names are absent (CocoaError, POSIXError, MachError and URLError code accessors, URLResourceValues members, Measurement, parts of URL and Calendar). Those that the other still-prebuilt overlays import from libswiftFoundation all resolve (checked with `llvm-nm -m`). The overlay needs the Foundation headers and API notes with the Swift names (NS_OPTIONS/NS_ENUM, bridges, DateFormatter, typed resource keys) in the SDK.
