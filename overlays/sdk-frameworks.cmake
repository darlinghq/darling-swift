# Copyright (C) 2026 Lubos Dolezel
#
# Swift overlays for SDK frameworks (IOKit, CoreAudio, ...), built from the sources of the Swift 5.2.2 release
# (apple/swift tag swift-5.2.2-RELEASE, stdlib/public/Darwin/<Framework>). Included from the parent CMakeLists.txt
# when the Swift toolchain was found, so ${OVERLAYS} and ${overlay_shims} are set.

add_darling_swift_library(IOKit
	SOURCES "${OVERLAYS}/IOKit/IOReturn.swift"
	MODULES Dispatch CoreFoundation ObjectiveC Darwin
	FLAGS ${overlay_shims}
	LIBRARIES IOKit)

add_darling_swift_library(CoreAudio
	SOURCES "${OVERLAYS}/CoreAudio/CoreAudio.swift"
	MODULES Dispatch CoreFoundation ObjectiveC Darwin
	FLAGS ${overlay_shims}
	LIBRARIES CoreAudio)

add_darling_swift_library(Compression
	SOURCES "${OVERLAYS}/Compression/Compression.swift"
	MODULES Foundation Dispatch CoreFoundation ObjectiveC Darwin
	FLAGS ${overlay_shims}
	LIBRARIES compression)
