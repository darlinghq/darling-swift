# arm64 Swift SDK overlays

Swift.org toolchains stopped shipping the Darwin SDK overlays, so the copies in this repository were x86_64-only (Swift 5.2.2). `build.sh` builds arm64 slices of four of them from the last open-source sources, and merges them into the existing universal binaries. The x86_64 slices are unchanged.

| Overlay | Sources | Notes |
|---|---|---|
| `libswiftDarwin` | `swiftlang/swift` `release/6.1`, `stdlib/public/Platform` (`Darwin.swift` and `tgmath.swift` pre-expanded with gyb) | Needed at build time by the other overlays: the Clang importer maps C `Boolean` to `Darwin.DarwinBoolean` |
| `libswiftObjectiveC` | `release/5.4`, `stdlib/public/Darwin/ObjectiveC` | Unmodified |
| `libswiftCoreFoundation` | `release/5.4` `CoreFoundation.swift`, plus `CGFloat.swift` from the 5.4 CoreGraphics overlay | Newer SDKs moved `CGFloat` into this overlay; it's declared `@_originallyDefinedIn(module: "CoreGraphics", ...)` so its symbols keep their `CoreGraphics` mangling |
| `libswiftDispatch` | `release/5.4`, `stdlib/public/Darwin/Dispatch` | `Schedulers+DispatchQueue.swift` is dropped (it needs Combine). `Darling+NewerSDK.swift` and a designated `DispatchWorkItem.init(flags:block:)` add APIs from newer SDKs |

All sources are part of the Swift project, licensed under the Apache License v2.0 with Runtime Library Exception, except `Dispatch/Darling+NewerSDK.swift`, `Dispatch/include/swift/Runtime/Debug.h` (a one-declaration stand-in for the Swift runtime header) and `tests/`.

## Coverage of what macOS 26 apps import

Measured against every binary in `/System/Applications` of a macOS 26.6.2 install:

- **ObjectiveC:** 14/14 symbols.
- **CoreFoundation:** 15/15, including the `$s12CoreGraphics7CGFloatV…` metadata and conformances.
- **Dispatch:** 93/104. The missing 11 are the Combine `Scheduler` conformance of `DispatchQueue` with its `SchedulerTimeType`/`SchedulerOptions` types, and `OS_dispatch_queue_serial_executor.asUnownedSerialExecutor()`, which needs macOS 14 libdispatch headers.

## Building

See the header of `build.sh` for the required toolchain, resource directory, and Darling SDK/ld64/libSystem paths. The Darling SDK must include the Clang module maps for Darwin, ObjectiveC, Dispatch, os and CoreFoundation, and the `sys/cdefs.h` default-platform fix. Without that fix, arm64 code links against `$UNIX2003` symbol variants that don't exist.

## Tests

`tests/objc_only.swift` and `tests/objc_cf.swift` cover an NSObject subclass with `@objc` methods and selectors, NSObject `Equatable`/`Hashable`, `autoreleasepool`, `ObjCBool`, CF types as `Hashable` (`_CFObject`), CFString round trips, and CGFloat. Build them for `arm64-apple-macosx26.0` against these overlays, link with Darling's ld64 (plus `-Xfrontend -disable-objc-attr-requires-foundation-module`, since there is no Foundation Swift overlay), and run them with `darling shell`.
