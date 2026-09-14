#!/bin/sh
# Build the arm64 slices of the Swift SDK overlays in this directory and merge them with the
# x86_64 slices already in the repository (Swift 5.2.2 builds from swift.org).
#
# Required environment:
#   SWIFT_TOOLCHAIN     usr/ directory of a Swift 6.3.3 toolchain (the Linux release works)
#   SWIFT_RESOURCE_DIR  usr/lib/swift from swift-6.3.3-RELEASE-osx.pkg (Swift/_Concurrency modules, shims, clang headers)
#   DARLING_SDK         Darling's MacOSX.sdk, including the Clang module maps and API notes for
#                       Darwin, ObjectiveC, Dispatch, os, CoreFoundation and the sys/cdefs.h default-platform fix
#   DARLING_LD          Darling's ld64 (build/src/external/cctools-port/cctools/ld64/src/aarch64-apple-darwin20-ld)
#   DARLING_LIBSYSTEM   Darling's built libSystem.B.dylib
#   DARLING_ROOT        installed Darling root (libexec/darling): libobjc and CoreFoundation are linked from it
# Optional:
#   LD_EXTRA_FLAGS      extra ld64 flags, e.g. the -dylib_file mappings Darling's own executables link with
set -eu

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/.." && pwd)
: "${SWIFT_TOOLCHAIN:?}" "${SWIFT_RESOURCE_DIR:?}" "${DARLING_SDK:?}" "${DARLING_LD:?}" "${DARLING_LIBSYSTEM:?}" "${DARLING_ROOT:?}"
LD_EXTRA_FLAGS=${LD_EXTRA_FLAGS:-}
out="$here/build"
mkdir -p "$out/modules" "$out/obj"

# build_module <Module> <sources...> [-- <extra swiftc -frontend flags>] [--link <extra ld inputs>]
build_module() {
	module=$1
	shift
	sources=""
	swift_flags=""
	link_inputs=""
	mode=src
	for arg in "$@"; do
		case "$arg" in
			--) mode=flags ;;
			--link) mode=link ;;
			*) case "$mode" in
				src) sources="$sources $arg" ;;
				flags) swift_flags="$swift_flags $arg" ;;
				link) link_inputs="$link_inputs $arg" ;;
			esac ;;
		esac
	done

	# Library evolution, like Apple's SDK overlays, so binaries built against the macOS SDK use the same access patterns.
	# shellcheck disable=SC2086
	"$SWIFT_TOOLCHAIN/bin/swiftc" -frontend -c $sources \
		-target arm64-apple-macosx26.0 -sdk "$DARLING_SDK" -resource-dir "$SWIFT_RESOURCE_DIR" \
		-module-cache-path "$out/module-cache" -swift-version 5 \
		-module-name "$module" -module-link-name "swift$module" -autolink-force-load \
		-enable-library-evolution -parse-as-library -O \
		-I "$out/modules" \
		-Xcc -fmodule-map-file="$here/shims/overlay-shims.modulemap" \
		-emit-module-path "$out/modules/$module.swiftmodule" \
		-o "$out/obj/$module.o" $swift_flags

	# shellcheck disable=SC2086
	"$DARLING_LD" -dylib -arch arm64 -platform_version macos 26.0 26.0 -syslibroot "$DARLING_SDK" \
		-install_name "/usr/lib/swift/libswift$module.dylib" \
		-compatibility_version 1.0.0 -current_version 1.0.0 \
		$LD_EXTRA_FLAGS \
		-L "$SWIFT_RESOURCE_DIR/macosx" -L "$out" \
		"$out/obj/$module.o" "$DARLING_LIBSYSTEM" "$DARLING_ROOT/usr/lib/libobjc.A.dylib" \
		-lswiftCore $link_inputs \
		-o "$out/libswift$module.dylib"
}

corefoundation="$DARLING_ROOT/System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation"

build_module Darwin "$here"/Darwin/*.swift
build_module ObjectiveC "$here/ObjectiveC/ObjectiveC.swift" -- -disable-objc-attr-requires-foundation-module --link -lswiftDarwin
build_module CoreFoundation "$here"/CoreFoundation/*.swift --link "$corefoundation" -lswiftDarwin
"$SWIFT_TOOLCHAIN/bin/clang++" -target arm64-apple-macosx26.0 -isysroot "$DARLING_SDK" -I "$here/Dispatch/include" \
	-std=c++17 -fobjc-arc -O2 -c "$here/Dispatch/Dispatch.mm" -o "$out/obj/Dispatch.mm.o"
"$SWIFT_TOOLCHAIN/bin/clang" -target arm64-apple-macosx26.0 -isysroot "$DARLING_SDK" -fobjc-arc -O2 \
	-c "$here/Dispatch/DarlingSerialExecutor.m" -o "$out/obj/DarlingSerialExecutor.m.o"
build_module Dispatch "$here"/Dispatch/*.swift --link "$out/obj/Dispatch.mm.o" "$out/obj/DarlingSerialExecutor.m.o" -lswiftObjectiveC -lswiftDarwin
build_module os "$here/os/os.swift" -- -Xcc -fmodule-map-file="$here/os/shims/module.modulemap" --link -lswiftDarwin -lswiftObjectiveC -lswiftDispatch
build_module XPC "$here/XPC/XPC.swift" -- -Xcc -fmodule-map-file="$here/XPC/shims/module.modulemap" --link -lswiftDarwin -lswiftObjectiveC -lswiftDispatch

for module in Darwin ObjectiveC CoreFoundation Dispatch os XPC; do
	dylib="libswift$module.dylib"
	llvm-lipo -thin x86_64 "$repo/$dylib" -output "$out/$dylib.x86_64" 2>/dev/null || cp "$repo/$dylib" "$out/$dylib.x86_64"
	llvm-lipo -create "$out/$dylib.x86_64" "$out/$dylib" -output "$repo/$dylib"
	rm "$out/$dylib.x86_64"
	echo "updated $dylib: $(llvm-lipo -archs "$repo/$dylib")"
done
