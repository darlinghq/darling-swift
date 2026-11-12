project(swift)

include(darling_lib)

set(DARLING_LIB_64BIT_ONLY TRUE)

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
	set_property(TARGET ${name} APPEND_STRING PROPERTY
		LINK_FLAGS " -Wl,-reexport_library,${CMAKE_CURRENT_SOURCE_DIR}/libswiftDarwin.dylib")
	install(TARGETS ${name} DESTINATION libexec/darling/usr/lib/swift)
endfunction()

add_swift_darwin_reexport(swift_errno swift_errno.S)
foreach(split
	swift_DarwinFoundation1 swift_DarwinFoundation2 swift_DarwinFoundation3
	swift_math swift_signal swift_stdio swift_time swiftsys_time swiftunistd)
	add_swift_darwin_reexport(${split} swift_darwin_split.S)
endforeach()

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
