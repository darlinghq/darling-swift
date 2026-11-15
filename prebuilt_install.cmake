# Copyright (C) 2026 Lubos Dolezel
#
# Installs the prebuilt dylibs of this directory (the Swift runtime and the Swift 5.2.2 overlays, unmodified files
# from swift.org's packages; they stay byte-identical in the repository).
#
# The 5.2.2 overlays name the libraries they depend on as @rpath/libswift*.dylib and carry no LC_RPATH, and macOS 26
# has no @rpath fallback, so a program that loads one fails with "no LC_RPATH's found". The copies that get installed
# differ from the repository files only in load-command paths: every @rpath/libswiftX.dylib dependency becomes
# /usr/lib/swift/libswiftX.dylib (and an @rpath install ID becomes the absolute one). They are produced in the build
# directory with the host install_name_tool built from cctools-port, then ad-hoc signed like every other image
# the build produces. Files without such a dependency are installed as they are.

file(GLOB DYLIBS "${CMAKE_CURRENT_SOURCE_DIR}/*.dylib")

# Names (after libswift) of libraries an overlay may name through @rpath: the prebuilt ones and the ones built from source.
set(SWIFT_REWRITE_NAMES
	Darwin ObjectiveC CoreFoundation CoreGraphics Dispatch Foundation os XPC IOKit CoreAudio Compression WebKit
	_errno _DarwinFoundation1 _DarwinFoundation2 _DarwinFoundation3 _math _signal _stdio _time sys_time unistd)
foreach(dylib IN LISTS DYLIBS)
	get_filename_component(name "${dylib}" NAME_WE)
	string(REGEX REPLACE "^libswift" "" name "${name}")
	list(APPEND SWIFT_REWRITE_NAMES "${name}")
endforeach()
list(REMOVE_DUPLICATES SWIFT_REWRITE_NAMES)

# "@rpath/libswift" as hex, for finding images that need rewriting without running a tool at configure time.
set(_rpath_marker "4072706174682f6c69627377696674")

set(change_args)
foreach(name IN LISTS SWIFT_REWRITE_NAMES)
	list(APPEND change_args -change "@rpath/libswift${name}.dylib" "/usr/lib/swift/libswift${name}.dylib")
endforeach()

set(rewritten)
set(unchanged)
foreach(dylib IN LISTS DYLIBS)
	get_filename_component(file "${dylib}" NAME)
	set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${dylib}")
	if (IS_SYMLINK "${dylib}")
		list(APPEND unchanged "${dylib}")
		continue()
	endif()
	# The load commands are at the start of the file.
	file(READ "${dylib}" head LIMIT 131072 HEX)
	string(FIND "${head}" "${_rpath_marker}" pos)
	if (pos EQUAL -1)
		list(APPEND unchanged "${dylib}")
		continue()
	endif()
	set(out "${CMAKE_CURRENT_BINARY_DIR}/prebuilt/${file}")
	string(REGEX REPLACE "\\.dylib$" "" ident "${file}")
	add_custom_command(
		OUTPUT "${out}"
		COMMAND "${CMAKE_COMMAND}" -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/prebuilt"
		COMMAND "${CMAKE_COMMAND}" -E copy "${dylib}" "${out}"
		COMMAND $<TARGET_FILE:install_name_tool_host> -id "/usr/lib/swift/${file}" ${change_args} "${out}"
		COMMAND $<TARGET_FILE:adhoc-sign> "--identifier=${ident}" "${out}"
		DEPENDS "${dylib}" install_name_tool_host adhoc-sign
		COMMENT "Giving ${file} absolute dependency paths"
		VERBATIM
	)
	list(APPEND rewritten "${out}")
endforeach()

if (rewritten)
	add_custom_target(swift_prebuilt_rewritten ALL DEPENDS ${rewritten})
endif()
install(FILES ${unchanged} ${rewritten} DESTINATION libexec/darling/usr/lib/swift)
