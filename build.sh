#!/bin/sh
set -e

version=$(cat version.txt)

mkdir -p build
cd build

# SWIFT_PKG can point at an already downloaded swift-<version>-RELEASE-osx.pkg.
if [ -n "${SWIFT_PKG:-}" ]; then
	cp "$SWIFT_PKG" source.pkg
else
	url="https://download.swift.org/swift-${version}-release/xcode/swift-${version}-RELEASE/swift-${version}-RELEASE-osx.pkg"
	if command -v wget >/dev/null 2>&1; then
		wget "$url" -O source.pkg
	else
		curl -L "$url" -o source.pkg
	fi
fi

echo "Extracting the PKG"
if command -v xar >/dev/null 2>&1; then
	xar -x -f source.pkg
else
	bsdtar -xf source.pkg
fi

echo "Extracting the payload"
gunzip < "swift-${version}-RELEASE-osx-package.pkg/Payload" | cpio -i

# Newer toolchains only ship the open-source runtime libraries (as universal arm64 + x86_64 binaries);
# the Darwin SDK overlays (libswiftAppKit, libswiftFoundation, ...) are no longer part of the pkg, so the
# older x86_64-only overlays already in this repository are left in place.
echo "Moving the useful files"
mv ./usr/lib/swift/macosx/libswift*dylib ../

# The textual module interfaces (both architectures) of the modules the runtime libraries implement.
# The Swift overlays are compiled against these; see README.md.
for module in Swift _Concurrency _StringProcessing _RegexParser RegexBuilder Observation Synchronization \
	Distributed _Builtin_float _Volatile Runtime _Differentiation SwiftOnoneSupport; do
	mkdir -p "../stdlib-modules/$module.swiftmodule"
	cp usr/lib/swift/macosx/"$module".swiftmodule/*-apple-macos.swiftinterface "../stdlib-modules/$module.swiftmodule/"
done
cd ..
rm -rf build
