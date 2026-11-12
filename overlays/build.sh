#!/bin/sh
# Build one architecture's slice of the Swift SDK overlays in this directory. Run it once per
# architecture, each against a Darling SDK/ld64/install of that architecture, then run merge.sh to
# combine the slices into the universal dylibs in the top-level directory.
#
# Required environment:
#   ARCH                x86_64 or arm64
#   SWIFT_TOOLCHAIN     usr/ directory of a Swift 6.3.3 toolchain (the Linux release works; swiftc -frontend
#                       cross-compiles to apple-macosx)
#   SWIFT_RESOURCE_DIR  usr/lib/swift from swift-6.3.3-RELEASE-osx.pkg (Swift/_Concurrency modules, shims, clang headers)
#   DARLING_SDK         Darling's MacOSX.sdk, including the Clang module maps and API notes for
#                       Darwin, ObjectiveC, Dispatch, os, XPC and CoreFoundation, and the sys/cdefs.h default-platform fix
#   DARLING_LD          Darling's ld64 (build/src/external/cctools-port/cctools/ld64/src/<arch>-apple-darwin20-ld)
#   DARLING_LIBSYSTEM   Darling's built libSystem.B.dylib for ARCH
#   DARLING_ROOT        installed Darling root (libexec/darling) for ARCH: libobjc and CoreFoundation are linked from it
# Optional:
#   LD_EXTRA_FLAGS      extra ld64 flags, e.g. the -dylib_file mappings Darling's own executables link with
# Output: build/$ARCH/libswift<Module>.dylib
set -eu

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/.." && pwd)
: "${ARCH:?}" "${SWIFT_TOOLCHAIN:?}" "${SWIFT_RESOURCE_DIR:?}" "${DARLING_SDK:?}" "${DARLING_LD:?}" "${DARLING_LIBSYSTEM:?}" "${DARLING_ROOT:?}"
LD_EXTRA_FLAGS=${LD_EXTRA_FLAGS:-}
case "$ARCH" in
	x86_64|arm64) ;;
	*) echo "ARCH must be x86_64 or arm64" >&2; exit 1 ;;
esac
# The Swift modules and objects are per-architecture; the module cache is shared by Clang's own hashing.
out="$here/build/$ARCH"
mkdir -p "$out/modules" "$out/obj"
target="$ARCH-apple-macosx26.0"

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
		-target "$target" -sdk "$DARLING_SDK" -resource-dir "$SWIFT_RESOURCE_DIR" \
		-module-cache-path "$out/module-cache" -swift-version 5 \
		-module-name "$module" -module-link-name "swift$module" -autolink-force-load \
		-enable-library-evolution -parse-as-library -O \
		-I "$out/modules" \
		-Xcc -fmodule-map-file="$here/shims/overlay-shims.modulemap" \
		-emit-module-path "$out/modules/$module.swiftmodule" \
		-o "$out/obj/$module.o" $swift_flags

	# shellcheck disable=SC2086
	"$DARLING_LD" -dylib -arch "$ARCH" -platform_version macos 26.0 26.0 -syslibroot "$DARLING_SDK" \
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
"$SWIFT_TOOLCHAIN/bin/clang++" -target "$target" -isysroot "$DARLING_SDK" -I "$here/Dispatch/include" \
	-std=c++17 -fobjc-arc -O2 -c "$here/Dispatch/Dispatch.mm" -o "$out/obj/Dispatch.mm.o"
build_module Dispatch "$here"/Dispatch/*.swift --link "$out/obj/Dispatch.mm.o" -lswiftObjectiveC -lswiftDarwin
build_module os "$here/os/os.swift" -- -Xcc -fmodule-map-file="$here/os/shims/module.modulemap" --link -lswiftDarwin -lswiftObjectiveC -lswiftDispatch
build_module XPC "$here/XPC/XPC.swift" -- -Xcc -fmodule-map-file="$here/XPC/shims/module.modulemap" --link -lswiftDarwin -lswiftObjectiveC -lswiftDispatch
