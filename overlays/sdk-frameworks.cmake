# Copyright (C) 2026 Lubos Dolezel
#
# Swift overlays for SDK frameworks (IOKit, CoreAudio, AppKit, ...), built from the sources of the Swift 5.2.2 release
# (apple/swift tag swift-5.2.2-RELEASE, stdlib/public/Darwin/<Framework>). Included from the parent CMakeLists.txt
# when the Swift toolchain was found, so ${OVERLAYS} and ${overlay_shims} are set.

add_darling_swift_library(IOKit
	SOURCES "${OVERLAYS}/IOKit/IOReturn.swift"
	MODULES Dispatch CoreFoundation ObjectiveC Darwin
	FLAGS ${overlay_shims}
	LIBRARIES IOKit)

add_darling_swift_library(CoreAudio
	SOURCES "${OVERLAYS}/CoreAudio/CoreAudio.swift" "${OVERLAYS}/CoreAudio/AudioChannelLayout.swift"
	MODULES Dispatch CoreFoundation ObjectiveC Darwin
	FLAGS ${overlay_shims}
	LIBRARIES CoreAudio)

# AppKit: the 5.2.2 overlay sources (AppKit.swift, AppKit_FoundationExtensions.swift, NSError.swift, NSEvent.swift,
# NSGraphics.swift, NSOpenGL.swift), unmodified. They compile against the declarations, API notes and module map of
# Darling's AppKit headers (nested type names, typed enums, the `__`-prefixed refined functions).
file(GLOB APPKIT_OVERLAY_SOURCES "${OVERLAYS}/AppKit/*.swift")
add_darling_swift_library(AppKit
	SOURCES ${APPKIT_OVERLAY_SOURCES}
	MODULES Foundation CoreGraphics Dispatch CoreFoundation ObjectiveC Darwin
	FLAGS ${overlay_shims}
	LIBRARIES AppKit Foundation)

add_darling_swift_library(Compression
	SOURCES "${OVERLAYS}/Compression/Compression.swift"
	MODULES Foundation Dispatch CoreFoundation ObjectiveC Darwin
	FLAGS ${overlay_shims}
	LIBRARIES compression)

# CoreText: AttributedString.AdaptiveImageGlyph and the CTAdaptiveImageGlyph conversions, written for Darling from the
# documented API. The CoreText Clang module comes from the SDK; the private CTAdaptiveImageGlyph class is declared by
# overlays/CoreText/shims. The conversion has package access (exported under its macOS mangled name), hence
# -package-name.
add_darling_swift_library(CoreText
	SOURCES "${OVERLAYS}/CoreText/CoreText.swift"
	MODULES Foundation CoreGraphics Dispatch CoreFoundation ObjectiveC Darwin
	WEAK_MODULES Combine
	FLAGS ${overlay_shims} -package-name swift-coretext
		-Xcc -fmodule-map-file=${OVERLAYS}/CoreText/shims/module.modulemap
	LIBRARIES CoreText Foundation)

# UniformTypeIdentifiers: UTType and UTTagClass over the framework's Objective-C UTType
# (imported as UTTypeReference through the framework's Clang module and API notes in the SDK). Written for Darling.
add_darling_swift_library(UniformTypeIdentifiers
	SOURCES "${OVERLAYS}/UniformTypeIdentifiers/UniformTypeIdentifiers.swift"
	MODULES Foundation Dispatch CoreFoundation ObjectiveC Darwin
	WEAK_MODULES Combine
	FLAGS ${overlay_shims}
	LIBRARIES UniformTypeIdentifiers Foundation)

# Network: NWConnection, NWListener, NWPath and the other Swift types over the nw_* C API of libnetwork. It imports the
# shim module _SwiftNetworkOverlayShims (overlays/shims/NetworkOverlayShims.h, part of ${overlay_shims}) and needs the
# SDK's Network Clang module.
file(GLOB NETWORK_SOURCES "${OVERLAYS}/Network/*.swift")
add_darling_swift_library(Network
	SOURCES ${NETWORK_SOURCES}
	MODULES Foundation Dispatch CoreFoundation ObjectiveC Darwin
	FLAGS ${overlay_shims}
	LIBRARIES Network Security)
