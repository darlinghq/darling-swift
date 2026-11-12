# Swift SDK overlays built from source

Swift.org toolchains stopped shipping the Darwin SDK overlays, so the copies in this repository were x86_64-only (Swift 5.2.2). `build.sh` builds six of them from source for one architecture at a time (x86_64 and arm64), and `merge.sh` combines the slices into universal binaries that replace the 5.2.2 ones. Four are built from the last open-source Swift sources; `os` and `XPC` were never open source, so they are written from Apple's public API documentation and the imported symbol names (no Apple code).

| Overlay | Sources | Notes |
|---|---|---|
| `libswiftDarwin` | `swiftlang/swift` `release/6.1`, `stdlib/public/Platform` (`Darwin.swift` and `tgmath.swift` pre-expanded with gyb) | Needed at build time by the other overlays: the Clang importer maps C `Boolean` to `Darwin.DarwinBoolean` |
| `libswiftObjectiveC` | `release/5.4`, `stdlib/public/Darwin/ObjectiveC` | Unmodified |
| `libswiftCoreFoundation` | `release/5.4` `CoreFoundation.swift`, plus `CGFloat.swift` from the 5.4 CoreGraphics overlay | Newer SDKs moved `CGFloat` into this overlay; it's declared `@_originallyDefinedIn(module: "CoreGraphics", ...)` so its symbols keep their `CoreGraphics` mangling |
| `libswiftDispatch` | `release/5.4`, `stdlib/public/Darwin/Dispatch` | `Schedulers+DispatchQueue.swift` is dropped (it needs Combine). `Darling+NewerSDK.swift` and a designated `DispatchWorkItem.init(flags:block:)` add APIs from newer SDKs. The `OS_dispatch_queue_serial_executor` class that `Darling+NewerSDK.swift` extends is defined by Darling's libdispatch |
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

See the header of `build.sh` for the required toolchain, resource directory, and Darling SDK/ld64/libSystem paths. Run it once per architecture (`ARCH=x86_64`, `ARCH=arm64`), each time against the SDK, ld64, libSystem and installed Darling root of that architecture, then `merge.sh Darwin ObjectiveC CoreFoundation Dispatch os XPC` (the modules are linked against each other, so build all of them for an architecture before merging). The Darling SDK must include the Clang module maps for Darwin, ObjectiveC, Dispatch, os, XPC and CoreFoundation, and the `sys/cdefs.h` default-platform fix. Without that fix, arm64 code links against `$UNIX2003` symbol variants that don't exist.

The toolchain is the Linux Swift 6.3.3 release (`swift-6.3.3-RELEASE-debian12.tar.gz` from download.swift.org); its `swiftc -frontend` cross-compiles to `apple-macosx`. `SWIFT_RESOURCE_DIR` is `usr/lib/swift` of `swift-6.3.3-RELEASE-osx.pkg`, the package the runtime in this repository comes from.

## Tests

`tests/os_xpc.swift` covers `Logger`, `os_log` with arguments, signpost IDs and intervals, `OSAllocatedUnfairLock` across threads, `XPCDictionary`/`XPCArray` and `XPCSession`. `tests/objc_only.swift` and `tests/objc_cf.swift` cover an NSObject subclass with `@objc` methods and selectors, NSObject `Equatable`/`Hashable`, `autoreleasepool`, `ObjCBool`, CF types as `Hashable` (`_CFObject`), CFString round trips, and CGFloat. Build them for `arm64-apple-macosx26.0` against these overlays, link with Darling's ld64 (plus `-Xfrontend -disable-objc-attr-requires-foundation-module`, since there is no Foundation Swift overlay), and run them with `darling shell`.
