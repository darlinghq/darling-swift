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
# The Swift overlays are compiled against these; see README.md. Copy every macOS interface the
# package ships, including private interfaces and modules added by newer releases, so that a bump
# of version.txt does not need another edit here.
find usr/lib/swift/macosx -type f -name '*apple-macos*.swiftinterface' -print | while IFS= read -r interface; do
	rel=${interface#usr/lib/swift/macosx/}
	target="../stdlib-modules/$rel"
	mkdir -p "$(dirname "$target")"
	cp "$interface" "$target"
done
cd ..
rm -rf build
