#!/bin/sh
set -e

version=$(cat version.txt)

mkdir -p build
cd build
wget "https://swift.org/builds/swift-${version}-release/xcode/swift-${version}-RELEASE/swift-${version}-RELEASE-osx.pkg" -O source.pkg

echo "Extracting the PKG"
xar -x -f source.pkg

echo "Extracting the payload"
gunzip < "swift-${version}-RELEASE-osx-package.pkg/Payload" | cpio -i

echo "Moving the useful files"
mv ./usr/lib/swift/macosx/libswift*dylib ../
cd ..
rm -rf build

