#!/bin/sh
# Copyright (C) 2026 Lubos Dolezel
#
# Combine the per-architecture overlay dylibs that build.sh left in build/<arch>/ into the universal
# dylibs in the top-level directory of this repository.
#
# Usage: merge.sh <module>...   (module names as in build.sh, e.g. Darwin ObjectiveC)
# Environment: ARCHS (default "x86_64 arm64"); every module must have been built for every architecture,
# so a universal dylib never mixes a rebuilt slice with an older one.
set -eu

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/.." && pwd)
ARCHS=${ARCHS:-"x86_64 arm64"}

[ $# -gt 0 ] || { echo "usage: $0 <module>..." >&2; exit 1; }
for module in "$@"; do
	inputs=""
	for arch in $ARCHS; do
		slice="$here/build/$arch/libswift$module.dylib"
		[ -f "$slice" ] || { echo "missing $slice: run build.sh with ARCH=$arch first" >&2; exit 1; }
		inputs="$inputs $slice"
	done
	# shellcheck disable=SC2086
	llvm-lipo -create $inputs -output "$repo/libswift$module.dylib"
	echo "updated libswift$module.dylib: $(llvm-lipo -archs "$repo/libswift$module.dylib")"
done
