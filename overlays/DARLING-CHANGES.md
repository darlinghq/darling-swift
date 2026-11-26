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
- **The Network shim.** `shims/NetworkOverlayShims.h` is the module `_SwiftNetworkOverlayShims` that the Network
  overlay of Swift 5.2.2 (`stdlib/public/Darwin/Network`) imports. It is the header of the same name from apple/swift
  `swift-5.2.2-RELEASE` (`stdlib/public/SwiftShims`, Apache-2.0 with Runtime Library Exception), with one change: the
  original `_swift_nw_parameters_create_custom_ip` did not return its result. The shim redeclares the functions that
  Network.framework exports but does not publish (`nw_endpoint_create_unix`, `nw_endpoint_copy_interface`,
  `nw_interface_create_with_name`, `NWCreateNSDataFromDispatchData`, ...), so libnetwork and the Network
  framework declare them with the same types.

## Data and NSData

`Foundation/Data.swift` is the `release/5.4` file, not a copy of swift-foundation's `Data.swift`, so it is not
compared against upstream line by line. Where it adopts a later upstream declaration, this section says so.

- **`Data` is `Sendable`**, as Apple documents. `Data` and its internal `InlineData`, `InlineSlice`, `LargeSlice` and
  `_Representation` conform to `Sendable`; the storage classes `__DataStorage` and `RangeReference` are
  `@unchecked Sendable`, because they hold mutable state and a deallocator closure that the compiler cannot check.
  These are the declarations swift-foundation's `Data.swift` has at `swift-6.3.3-RELEASE`. Each `@unchecked Sendable`
  has a comment saying why it is sound: no two `Data` values can mutate the same bytes, because every mutation path
  checks the reference count of the storage and then calls `ensureUniqueBufferReference`. Paths read for that claim:
  the subscript setter, `reserveCapacity`, `append`, `resetBytes`, `replaceSubrange`, `withUnsafeMutableBytes` and
  `_uniqueMutableBuffer` (the last two since the commits before this one). The
  exceptions are `bytesNoCopy` storage, written in place by contract, and the `Data` values that `NSData.regions` returns, which
  are `bytesNoCopy` views (see the open items below). `Sendable` is a marker protocol and adds no symbol to
  `libswiftFoundation`: a scratch library built with library evolution showed none, and the reviewer's `llvm-nm` of
  the built arm64 Debug `libswiftFoundation` found no `Sendable` conformance symbol for `Data` in the export table
  (checked for absence). Clients in language mode 6, for example CryptoKit.framework, need it.
  `tests/data_sendable.swift` is the check.
  **Why the series travels together.** Once `Data` is `Sendable`, a write that reaches another `Data` through shared
  bytes is an unflagged data race, so the write-through paths are closed or recorded in the same series. The commits
  are independent and can be split into separate PRs if the maintainers prefer.

  Verification scope. Built: the final candidate (`local/integration-2215d`) with `ninja swiftCryptoKit`, arm64 Debug: exit
  0, 29.2 s, 0 errors and no lifetime warning; it compiled `libswiftFoundation` and linked both libraries (CryptoKit
  was not recompiled; CryptoKit builds in language mode 6 with `Data` Sendable). The intermediate commits were NOT built one by one. Run:
  `tests/data_sendable.swift` (built with `-swift-version 6`) printed 3 ok, 0 FAIL against each of the four variants
  (d-fixed, d-unfixed-helper, d-unfixed-wumb, d-unfixed-guard) in a Darling guest on a refresh prefix plus this overlay,
  with hand-linked arm64 Debug test binaries, not on `master` and not on a clean install (the full matrix is in the
  verification scope below).
- **`Data.bytes`, `.span`, `.mutableBytes` and `.mutableSpan`** (`RawSpan`, `Span<UInt8>`, `MutableRawSpan`,
  `MutableSpan<UInt8>`, documented by Apple since macOS 10.14.4) replace the two unavailable `bytes` and
  `mutableBytes` stubs of the `release/5.4` file. Origin: `Sources/FoundationEssentials/Data/Data.swift` of
  [swiftlang/swift-foundation](https://github.com/swiftlang/swift-foundation) at `swift-6.3.3-RELEASE` (commit
  `dbacc67779dc0a41ddc9493acbaa332d76c9fb03`), lines 2212 to 2326 there; Apache License v2.0 with the Runtime Library
  Exception, copyright The Swift Project authors, covered by the existing `LICENSE-swift-foundation.md` and
  `NOTICE-swift-foundation.txt`. Upstream's comments are not copied. Differences from upstream: the unique-storage
  step of the two mutable accessors is one helper, `_uniqueMutableBuffer` (upstream repeats it; its
  swiftlang/swift#81218 workaround block is therefore not needed), the `unsafe` expressions are left out because the
  module is not built with strict memory safety, and `@_addressableForDependencies` on `Data` is unconditional
  because the toolchain is fixed at 6.3.3, and the lifetime attribute is spelled `@_lifetime` (see below).
  `Data.swift` is identical between the tag and the pinned checkout (`git diff dbacc67 HEAD` on that path is empty).
  Compiling it needs `import Builtin` (in the branch of the file that Darling compiles: the overlay is built without
  `DEPLOYMENT_RUNTIME_SWIFT`, which only swift-corelibs-foundation sets) and the experimental features `Lifetimes`,
  `BuiltinModule` and `AddressableTypes`, set on the Foundation target in `CMakeLists.txt`.
  Behaviour taken from upstream, none of it documented by Apple (GUESS that it is acceptable, it is the open-source
  code Apple ships): an empty `Data` gives an empty span; the mutable accessors make the storage unique first (a copy
  taken earlier is unchanged). Same rule as the existing `withUnsafeMutableBytes`: storage that the `Data` does not own
  (`bytesNoCopy`, capacity equal to length) is written in place.
  Two more differences from upstream:
  - **`@_lifetime` and `Lifetimes`.** swift-foundation spells the attribute `@lifetime` and enables `LifetimeDependence`.
    With the 6.3.3 toolchain that combination compiled but made `@lifetime` inert: the first build of this overlay
    gave four `Unsupported use of @lifetime, use @_lifetime` warnings. The overlay uses `@_lifetime` and `Lifetimes`;
    on a stand-in struct with swiftc 6.3.3 (library evolution, `-O` and `-Onone`) that compiles without a warning, and
    `@_lifetime` with `LifetimeDependence` is an error. The whole Foundation module with `Lifetimes` and `@_lifetime`
    builds: the integration build above had exit 0, 0 errors and no lifetime warning.
  - **`_uniqueMutableBuffer` also calls `storage.ensureUniqueBufferReference()`.** A `Data` made by
    `Data(referencing:)` holds the `NSData` bytes in a storage with capacity 0 (`isExternallyOwned`). Upstream's
    accessors (Data.swift of swift-foundation, `mutableBytes` and `mutableSpan`) check only the reference count, so a
    write through `mutableSpan` or `mutableBytes` could reach the `NSData`; this overlay copies that storage first.
    `bytesNoCopy` storage has capacity equal to its length and is still written in place. The aliasing was observed
    under Darling: test binaries compiled against the module without this call changed the `NSData` and a second
    `Data` made from it, so Darling's `NSData` does return itself from `copy` for an immutable object. How upstream
    behaves for its own `Data(referencing:)` was not checked.
  - **`ensureUniqueBufferReference` does not unwrap a nil `_bytes` when the length is 0.** The helper calls it for
    every slice. An empty slice that does not start at index 0 (`base[10..<10]`) stays a slice that shares its parent's
    storage; while the parent is alive `ensureUniqueReference` replaces the storage by `mutableCopy` of an empty range,
    which has capacity 0 and no bytes, and the `newLength == 0` branch then moved from `_bytes!` and trapped (read from
    the code; `mutableSpan` and `mutableBytes` on such a slice were the cases). The branch now copies only when
    `_bytes` is non-nil, the same guard swift-foundation has (swiftlang/swift-foundation PR 2058, current `main` at
    commit `511394753aa873fd390674301594b4bb8460a74b`, `DataStorage.swift`; Apache License v2.0 with the Runtime
    Library Exception). The function is `@usableFromInline` code in `libswiftFoundation`, not inlined into clients, so
    this fix needs the rebuilt dylib, unlike the helper itself.
    Evidence: in the guest, with this guard removed from the dylib, `tests/data_span.swift` dies with SIGTRAP in the
    live-parent empty-slice case; with it the case passes.

- **`Data.withUnsafeMutableBytes` copies storage that the `Data` does not own.** `InlineSlice.withUnsafeMutableBytes`
  and `LargeSlice.withUnsafeMutableBytes` (the `release/5.4` code, and so `Data.withUnsafeMutableBytes`) checked only
  the reference count of the storage. A `Data` made by `Data(referencing:)` holds the `NSData` bytes in a storage with
  capacity 0, so a write through `withUnsafeMutableBytes` reached the `NSData` and every `Data` made from it later.
  Both functions now call `storage.ensureUniqueBufferReference()` after `ensureUniqueReference()`, the same two lines
  as `_uniqueMutableBuffer`. `bytesNoCopy` storage (capacity equal to length) is still written in place. Observed in a
  Darling guest without the change: the write reached the `NSData` at 15 and 100000 bytes, for referencing slices (40
  and 100000 bytes) and at `Int32.max` bytes. A bridged `third = (first as NSData) as Data` can share the storage with
  `first` by reading the code, so `third.withUnsafeMutableBytes { $0[0] = 1 }` would change `first`; that was NOT
  reproduced in the guest with the direct `(x as NSData) as Data` (the compiler can cancel the two bridge calls), and
  the round-trip cases now also hop through an `NSArray` in a function that is never inlined; they passed in the guest without
  the fix too, so round-trip aliasing remains expected by reading the code and not reproduced, and those cases do not
  discriminate this fix.
  `tests/data_nsdata_aliasing.swift` holds the cases. GUARDS in it, which cannot fail by design or pass in every
  variant: the 1 and 14-byte cases (inline storage, copied by construction) and the four other writers below. Other
  write paths, read for the same gap: the subscript setter (`storage.set`), `replaceSubrange` and `append`
  (`storage.replaceBytes`) and `resetBytes` all call `ensureUniqueBufferReference`, and the test checks the four.
  `Data(contentsOf:)` with a mapped file goes through `Data(referencing:)`, so writing to such a `Data` now copies the
  mapping first; before, the write went to the mapping, and a crash on a read-only mapping was possible (GUESS: not
  tried).

- **Left open: `NSData.regions`.** `NSData.regions` (`Foundation/NSData+DataProtocol.swift`) returns one
  `Data(bytesNoCopy:)` over the bytes of the `NSData`, with a deallocator that keeps the `NSData` alive. That is what
  swift-corelibs-foundation does (commit `f41070b9399539519cc0432a75972fdcfd74371f`, `Sources/Foundation/NSData+DataProtocol.swift`
  lines 33 to 41, over `NSData.enumerateBytes`, `Sources/Foundation/NSData.swift` lines 637 to 645, which hands out
  `bytes` as one range; Apache-2.0, re-read at that commit), so it is not changed here. `bytesNoCopy` storage is
  written in place, by contract, so writing to a region changes the `NSData`: `var r = (a as NSData).regions[0];
  r[0] = 9` changes `a[0]` for a `Data` `a` (read from the code, not run); and for an `NSMutableData` the pointer can
  dangle after the object reallocates. NOT fixed; whether Darling should diverge from corelibs here is a question for
  the maintainers.
- **Left open: binaries that do not take these fixes.** The bodies that were fixed are `@inlinable` or
  `@_alwaysEmitIntoClient`, so a binary built against an older Foundation module keeps the old behaviour until it is
  rebuilt. An app compiled on macOS inlines Apple's accessor body (swift-foundation's version of it checks only the
  reference count for `mutableBytes` and `mutableSpan`), so such an app can still write through for
  `Data(referencing:)` storage under Darling.
- Known limitations of the Data storage are recorded separately and are not part of this series.
- **Expected fixed (by reading the code; not run): `withUnsafeMutableBytes` on an empty slice whose parent is alive.** In the `release/5.4` code,
  `base[10..<10].withUnsafeMutableBytes { _ in }` with `base` still referenced trapped: the slice's storage is a copy
  of an empty range with no bytes, and `storage.withUnsafeMutableBytes(in:)` unwraps `_bytes`. With the `_bytes` guard
  of the accessor commit and the call this series adds to `withUnsafeMutableBytes`, that
  storage is given bytes before the closure runs, so the trap is expected to be gone. This is by reading the code: no
  test covers the `withUnsafeMutableBytes` path and it was not run. (The accessor path of the same scenario trapped in
  the guest without the guard.)

  Verification scope. Built: the final candidate (`local/integration-2215d`, the tree whose Foundation code equals the last commit of
  this series) with `ninja swiftCryptoKit`, arm64 Debug: exit 0, 29.2 s, 0 errors and no lifetime warning; it compiled
  `libswiftFoundation` and linked both libraries (the Swift of CryptoKit was not recompiled: its module input was unchanged). The intermediate commits of this series were NOT built one by one; the
  tree before the `withUnsafeMutableBytes` commit is approximated by the d-unfixed-wumb variant and the tree without the
  helper fix by the d-unfixed-helper variant (below). Run: in a Darling guest on a refresh prefix plus this overlay, with
  hand-linked arm64 Debug test binaries, not on `master` and not on a clean install; each variant had its own
  `libswiftFoundation` and modules.
  - d-fixed (the final candidate): `data_span` PASS 111 ok, 0 FAIL, `data_nsdata_aliasing` PASS 26/0, `data_sendable` PASS 3/0.
  - d-unfixed-helper (the helper's `ensureUniqueBufferReference` call removed): `data_span` FAIL, 96 ok, 15 FAIL, namely
    the `NSData` cases at 15 and 100000 bytes (the `mutableSpan` and `mutableBytes` writes and the `Data` made from the
    `NSData` afterwards), four round-trip lines at 15 and 100000 bytes (the cause was not isolated), the two referencing
    slices (40 and 100000 bytes) with their `mutableBytes` write, and the `Int32.max` `NSData` case; `data_nsdata_aliasing` PASS 26/0; `data_sendable` PASS 3/0.
  - d-unfixed-wumb (the `withUnsafeMutableBytes` fix removed): `data_nsdata_aliasing` FAIL, 19 ok, 7 FAIL, namely the
    `withUnsafeMutableBytes` write and the later `Data` at 15 and 100000 bytes (4), the referencing slices at 40 and
    100000 bytes (2) and the `Int32.max` case (1); `data_span` PASS 111/0; `data_sendable` PASS 3/0.
  - d-unfixed-guard (the `_bytes` guard in `ensureUniqueBufferReference` removed; it lives in the dylib, the module is
    the same as d-fixed, so the dylib decides for it): `data_span` CRASHES with SIGTRAP (exit 133, stderr empty, no
    stdout when piped); a re-run under a pty stops in the live-parent empty-slice case (`data_span.swift` lines 38 to
    43) right after `ok: an empty slice gives empty spans`, so that case discriminates the guard; `data_nsdata_aliasing` PASS 26/0; `data_sendable` PASS 3/0.
  - Against d-fixed: `cryptokit_smoke` PASS (9 ok) and the CryptoKit known-answer tests PASS (hash 27, aead 64, curves
    44), 0 FAIL.
  The helper and the `withUnsafeMutableBytes` bodies are `@_alwaysEmitIntoClient` or `@inlinable`, so for those cases
  the module that a test is compiled against decides, not the dylib.

  Round trip through the bridge pair: that a write to a `Data` that went through `(x as NSData) as Data` reaches the
  first `Data` is expected by reading the code and NOT reproduced in the guest. The direct `(x as NSData) as Data` and
  the variant that hops through an `NSArray` in an `@inline(never)` function both passed without the
  `withUnsafeMutableBytes` fix, so these round-trip cases do not discriminate that fix; they stay as guards. The
  round-trip lines of `data_span` that failed without the helper fix are listed above with their cause not isolated.

  Still GUESS: that `@_addressableForDependencies` is not an ABI change, and that macOS 26 does not export the four removed names,
  `_$s10Foundation4DataV5bytesSVvg`, `_$s10Foundation4DataV5bytesSVvpMV`, `_$s10Foundation4DataV12mutableBytesSvvg`
  and `_$s10Foundation4DataV12mutableBytesSvvpMV`, which only a Mac can confirm. CryptoKit.framework needs these four
  members.

# How CryptoKit.framework differs from swift-crypto

`CryptoKit.framework` is the `Crypto` module of [apple/swift-crypto](https://github.com/apple/swift-crypto) at tag
`5.1.2` (commit `3280a5f72874d2f73bf25551bbb64f524c76d834`), Apache License v2.0, with BoringSSL (Apache-2.0) and
XKCP (CC0-1.0) as vendored by swift-crypto; `CryptoKit/NOTICE.md` has the notices. Unlike the Foundation overlay no
upstream file is copied into this repository: the files are compiled from a checkout (`SWIFT_CRYPTO_SOURCE_DIR`) and
the differences below are made on a copy in the build directory, so there are no `// Darling:` comments.

- **Module name.** Built with `-module-name CryptoKit`. The 92 `#if canImport(CryptoKit)` tests of the API files
  (which re-export Apple's CryptoKit when true) become `#if canImport(CryptoKit) && !DARLING_CRYPTOKIT_MODULE`, and
  `-DDARLING_CRYPTOKIT_MODULE` is defined, so the implementation in the `#else` branch is compiled. The four
  `Crypto.X` qualifiers (`Digests/HashFunctions.swift`, `Message Authentication Codes/MACFunctions.swift`,
  `HPKE/Ciphersuite/HPKE-KexKeyDerivation.swift`, `HPKE/Ciphersuite/KEM/Conformances/DHKEM.swift`) become
  `CryptoKit.X`. `CryptoKit/rewrite-sources.cmake` does both and asserts the counts. To see the difference, diff the
  build directory's `cryptokit-src` against `Sources/Crypto` of the checkout: 99 changed lines.
- **Library evolution.** `add_darling_swift_library` always compiles with `-enable-library-evolution`, which
  swift-crypto has never been built with. The first build found one class of error that comes from it: an
  `@inlinable` initializer of a struct that is not `@frozen` that assigns `self.x` directly. `@inlinable` becomes
  `@usableFromInline` on exactly three initializers, named by file and text in `CryptoKit/rewrite-sources.cmake`
  (rule 3, each must occur once, else the build stops before writing): `init(rawRepresentation:)` of
  `OpenSSLCurve25519PublicKeyImpl` in `Keys/EC/BoringSSL/Ed25519_boring.swift` (line 109 in 5.1.2) and in
  `X25519Keys_boring.swift` (line 39), and `init(wrapping:)` of `OpenSSLNISTCurvePublicKeyImpl` in
  `NISTCurvesKeys_boring.swift` (line 119). A scan of every `@inlinable` or `@_alwaysEmitIntoClient` initializer in
  `Sources/Crypto` found no other one that assigns a stored property without delegating (done by script). Reproduced
  and fixed on a stand-in file with the toolchain's swiftc (library evolution on: the error with `@inlinable`, none
  with `@usableFromInline`), then on the real sources: with these three rules and the Foundation changes
  (`Data: Sendable`, the span accessors) `ninja swiftCryptoKit` compiles and links the whole module (5 min 16 s,
  arm64 Debug), so no fourth initializer needed a rule. Any other `@inlinable` or `@usableFromInline` fix that a
  later tag needs becomes another rule here.
- **Failed AEAD open.** On macOS `AES.GCM.open` and `ChaChaPoly.open` throw `CryptoKitError.authenticationFailure` when the
  tag does not authenticate. swift-crypto's BoringSSL path throws `underlyingCoreCryptoError(error: <BoringSSL code>)`,
  because on Apple platforms swift-crypto re-exports Apple's CryptoKit and this path only runs elsewhere. Rules 4 and 5
  of `CryptoKit/rewrite-sources.cmake` (counts asserted): the two failed-open sites of
  `CryptoBoringWrapper/AEAD/BoringSSLAEAD.swift` (the wrapper, which cannot name `CryptoKitError`) throw
  `CryptoBoringWrapperError.authenticationFailure` when BoringSSL's newest error is the cipher library's bad-decrypt
  error, and keep `internalBoringSSLError()` for any other failure; the two `open` wrappers in Crypto's
  `ChaChaPoly_boring.swift`, which already convert the wrapper's `underlyingCoreCryptoError`, convert
  `authenticationFailure` to `CryptoKitError.authenticationFailure`. Pinned by `tests/cryptokit_vectors.swift`.
- **Backports on every toolchain.** `Util/Backports.swift` of swift-crypto declares `ContiguousBytes.withBytes` and the
  `MutableRawSpan` byte subscript under `#if compiler(<6.4)`, because a Swift 6.4 toolchain provides both. CryptoKit
  is compiled against the Darling SDK's modules, not the toolchain's own: the Foundation overlay (swift-foundation at
  `swift-6.3.3-RELEASE`) and the standard library module interfaces in `stdlib-modules`, which have neither API
  whichever compiler builds them. Rule 6 of `CryptoKit/rewrite-sources.cmake` (the guard must occur once) turns the
  guard into `#if true`, so the two declarations, internal to the CryptoKit module, exist with every toolchain. Found
  with a 6.4.2 toolchain, where `HMAC.swift` stopped at "value of type 'H.Digest' has no member 'withBytes'"; the
  overlays and CryptoKit build with 6.3.3 and 6.4.2 (x86_64 and arm64).
- **Files left out.** `CryptoError_boring.swift` and `_CryptoModuleAnchor.swift` of `Crypto` (see README.md, CryptoKit),
  the three socket files of BoringSSL, and every other target of the package.
- **Flags of Package.swift that are carried:** `-package-name com.apple.swift-crypto`, the experimental features
  `Lifetimes` and `SourceWarningControl`, the upcoming feature `MemberImportVisibility`, and language mode 6 (given
  as `-swift-version 6`, after the 5 that the function passes; it takes effect: the first build in that mode reported
  the Sendable errors for `Data` that exist only in language mode 6).
- **Platform branches that take the Darwin side.** `Util/BoringSSL/Zeroization_boring.swift` (`!canImport(Darwin)`,
  so the `memset_s` shim over `OPENSSL_cleanse` is not compiled), `HPKE/Ciphersuite/HPKE-Utils.swift` (`import
  Darwin`) and `CryptoBoringWrapper/Util/RandomBytes.swift` (`SystemRandomNumberGenerator`). The framework therefore
  depends on Darling's `memset_s`, `getentropy` and `pthread_atfork`.
- **CryptoBoringWrapper** is compiled with `add_darling_swift_object`, like the `_RopeModule` of the Foundation
  overlay, and its symbols are unexported.
- **Native code.** The BoringSSL and XKCP sources are unchanged. The C++ files get `-std=c++17 -fno-exceptions
  -fno-rtti`, which swift-crypto's `Package.swift` does not pass (it sets only the C++ standard); that BoringSSL
  compiles that way is verified by the build: all 243 files compile with those flags (`build.ninja` of the build shows
  them on the compile rules; a grep also found no `virtual` under `crypto/` and `include/`). All native sources of the
  arm64 slice also get `-Xarch_arm64 -march=armv8-a+crypto`: Darling's arm64 default (`-mcpu=generic`) defines neither
  `__ARM_FEATURE_AES` nor `__ARM_FEATURE_SHA2`, and BoringSSL's `crypto/cpu_aarch64_apple.cc` stops with `#error`
  without them. The arm64 slice therefore assumes the AES and SHA extensions at run time (SIGILL on a CPU without
  them).
- **Not in the framework:** `SecureEnclave` and `CorecryptoCurveType`, which swift-crypto does not have.
