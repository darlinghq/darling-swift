project(swift)

include(darling_lib)

set(DARLING_LIB_64BIT_ONLY TRUE)

# The Swift overlays that are built from source need the Swift toolchain (see cmake/swift_toolchain.cmake in the
# main repository); without one they are skipped.
set(DARLING_SWIFT_STDLIB_MODULES "${CMAKE_CURRENT_SOURCE_DIR}/stdlib-modules")
set(DARLING_SWIFT_RUNTIME_DIR "${CMAKE_CURRENT_SOURCE_DIR}")

if (SWIFT_TOOLCHAIN_FOUND)
	set(OVERLAYS "${CMAKE_CURRENT_SOURCE_DIR}/overlays")
	set(overlay_shims -Xcc -fmodule-map-file=${OVERLAYS}/shims/overlay-shims.modulemap)

	file(GLOB DARWIN_SOURCES "${OVERLAYS}/Darwin/*.swift")
	add_darling_swift_library(Darwin
		SOURCES ${DARWIN_SOURCES}
		FLAGS ${overlay_shims})

	add_darling_swift_library(ObjectiveC
		SOURCES "${OVERLAYS}/ObjectiveC/ObjectiveC.swift"
		MODULES Darwin
		FLAGS ${overlay_shims} -disable-objc-attr-requires-foundation-module)

	file(GLOB COREFOUNDATION_SOURCES "${OVERLAYS}/CoreFoundation/*.swift")
	add_darling_swift_library(CoreFoundation
		SOURCES ${COREFOUNDATION_SOURCES}
		MODULES Darwin
		FLAGS ${overlay_shims}
		LIBRARIES CoreFoundation)

	# OS_OBJECT_SWIFT3 makes the dispatch headers declare the OS_dispatch_source_* protocols, as when Swift imports them.
	file(GLOB DISPATCH_SOURCES "${OVERLAYS}/Dispatch/*.swift")
	add_darling_swift_library(Dispatch
		SOURCES ${DISPATCH_SOURCES}
		MODULES ObjectiveC Darwin
		FLAGS ${overlay_shims}
		NATIVE_SOURCES "${OVERLAYS}/Dispatch/Dispatch.mm"
		NATIVE_FLAGS -std=c++17 -fobjc-arc -DOS_OBJECT_SWIFT3=1 -I${OVERLAYS}/Dispatch/include)

	add_darling_swift_library(os
		SOURCES "${OVERLAYS}/os/os.swift"
		MODULES Dispatch ObjectiveC Darwin
		FLAGS ${overlay_shims} -Xcc -fmodule-map-file=${OVERLAYS}/os/shims/module.modulemap)

	add_darling_swift_library(XPC
		SOURCES "${OVERLAYS}/XPC/XPC.swift"
		MODULES Dispatch ObjectiveC Darwin
		FLAGS ${overlay_shims} -Xcc -fmodule-map-file=${OVERLAYS}/XPC/shims/module.modulemap)

	# CGFloat and the CoreGraphics Swift API. The module re-exports libswiftCoreFoundation, which defines CGFloat
	# as the SDK's CoreGraphics does, so binaries that look it up through libswiftCoreGraphics still find it.
	file(GLOB COREGRAPHICS_SOURCES "${OVERLAYS}/CoreGraphics/*.swift")
	add_darling_swift_library(CoreGraphics
		SOURCES ${COREGRAPHICS_SOURCES}
		MODULES CoreFoundation ObjectiveC Darwin
		FLAGS ${overlay_shims}
		LIBRARIES CoreGraphics)
	reexport(swiftCoreGraphics swiftCoreFoundation "${CMAKE_CURRENT_BINARY_DIR}/libswiftCoreFoundation.dylib")

	# Foundation. AttributedString keeps its text in swift-collections' BigString, so two of that project's modules
	# (overlays/Collections) are compiled without library evolution and linked into libswiftFoundation.dylib, which
	# keeps their symbols out of its export table.
	file(GLOB_RECURSE ROPE_SOURCES "${OVERLAYS}/Collections/RopeModule/*.swift")
	file(GLOB_RECURSE COLLECTIONS_UTILITIES_SOURCES "${OVERLAYS}/Collections/InternalCollectionsUtilities/*.swift")
	add_darling_swift_object(InternalCollectionsUtilities SOURCES ${COLLECTIONS_UTILITIES_SOURCES})
	add_darling_swift_object(_RopeModule SOURCES ${ROPE_SOURCES} MODULES InternalCollectionsUtilities)
	file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/foundation-unexported.txt"
		"_$s*11_RopeModule*\n_$s*28InternalCollectionsUtilities*\n")
	file(GLOB FOUNDATION_SOURCES "${OVERLAYS}/Foundation/*.swift")
	add_darling_swift_library(Foundation
		SOURCES ${FOUNDATION_SOURCES}
		MODULES _RopeModule InternalCollectionsUtilities CoreGraphics os XPC CoreFoundation Dispatch ObjectiveC Darwin
		FLAGS ${overlay_shims} -package-name swift-foundation
			# Foundation's NSAppleEventDescriptor.h includes <AE/AE.h>, which the SDK does not expose by itself yet.
			-Xcc -I${DARLING_TOP_DIRECTORY}/src/frameworks/CoreServices/include
		OBJECTS "${_RopeModule_OBJECT}" "${InternalCollectionsUtilities_OBJECT}"
		LINK_FLAGS -Wl,-unexported_symbols_list,${CMAKE_CURRENT_BINARY_DIR}/foundation-unexported.txt
		LIBRARIES Foundation CoreFoundation icucore)
	set_property(TARGET swiftFoundation APPEND PROPERTY LINK_DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/foundation-unexported.txt")
endif()

# Newer SDKs split parts of the Darwin overlay out of libswiftDarwin.dylib into
# further dylibs, and binaries built against those SDKs bind the symbols to the
# split libraries by library ordinal. This tree keeps the whole overlay in
# libswiftDarwin.dylib, so each split library re-exports it and defines nothing.
function(add_swift_darwin_reexport name source)
	set(DYLIB_INSTALL_NAME "/usr/lib/swift/lib${name}.dylib")
	add_darling_library(${name} SHARED ${source})
	target_link_libraries(${name} system)
	set_target_properties(${name} PROPERTIES
		LINKER_LANGUAGE C
		OUTPUT_NAME "${name}"
	)
	reexport(${name} swiftDarwin "${CMAKE_CURRENT_BINARY_DIR}/libswiftDarwin.dylib")
	install(TARGETS ${name} DESTINATION libexec/darling/usr/lib/swift)
endfunction()

if (SWIFT_TOOLCHAIN_FOUND)
	add_swift_darwin_reexport(swift_errno swift_errno.S)
	foreach(split
		swift_DarwinFoundation1 swift_DarwinFoundation2 swift_DarwinFoundation3
		swift_math swift_signal swift_stdio swift_time swiftsys_time swiftunistd)
		add_swift_darwin_reexport(${split} swift_darwin_split.S)
	endforeach()
endif()

set(DYLIB_INSTALL_NAME "/usr/lib/swift/libswiftWebKit.dylib")
add_darling_library(swiftWebKit SHARED
	libswiftWebKit.S
)
target_link_libraries(swiftWebKit system)
set_target_properties(swiftWebKit PROPERTIES
	LINKER_LANGUAGE C
	OUTPUT_NAME "swiftWebKit"
)
install(TARGETS swiftWebKit DESTINATION libexec/darling/usr/lib/swift)

file(GLOB DYLIBS "*.dylib")
install(FILES ${DYLIBS} DESTINATION libexec/darling/usr/lib/swift)
