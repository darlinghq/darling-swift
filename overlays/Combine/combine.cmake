# Copyright (C) 2026 Lubos Dolezel
#
# Combine.framework, built from OpenCombine (MIT, https://github.com/OpenCombine/OpenCombine) as the Swift module
# Combine, so the mangled names match what applications import from Apple's framework. Included from the parent
# CMakeLists.txt when the Swift toolchain was found.
#
# OPENCOMBINE_SOURCE_DIR is a checkout of darlinghq/OpenCombine (the main repository's src/external/OpenCombine
# submodule). It is never written to: the sources are copied into the build directory and the patches in
# overlays/Combine/patches are applied to the copy, as the framework needs a few changes OpenCombine does not make
# for a module built with library evolution. overlays/Combine/helpers.c replaces OpenCombine's C++ helper file so
# that the framework needs no C++ runtime.

set(OPENCOMBINE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../OpenCombine" CACHE PATH
	"Checkout of OpenCombine (src/external/OpenCombine)")
if (NOT EXISTS "${OPENCOMBINE_SOURCE_DIR}/Sources/OpenCombine")
	message(FATAL_ERROR "OPENCOMBINE_SOURCE_DIR (${OPENCOMBINE_SOURCE_DIR}) is not an OpenCombine checkout: fetch "
		"the submodules (git submodule update --init) or point OPENCOMBINE_SOURCE_DIR at one")
endif()
find_program(PATCH_PROGRAM patch)
if (NOT PATCH_PROGRAM)
	message(FATAL_ERROR "patch is needed to build Combine from OpenCombine")
endif()

set(OPENCOMBINE_SWIFT_DIR "${OPENCOMBINE_SOURCE_DIR}/Sources/OpenCombine")
set(OPENCOMBINE_HELPERS_INCLUDE "${OPENCOMBINE_SOURCE_DIR}/Sources/COpenCombineHelpers/include")
set(COMBINE_PATCH_DIR "${CMAKE_CURRENT_SOURCE_DIR}/overlays/Combine/patches")
set(COMBINE_SOURCE_COPY "${CMAKE_CURRENT_BINARY_DIR}/combine-src")

file(GLOB_RECURSE combine_orig CONFIGURE_DEPENDS RELATIVE "${OPENCOMBINE_SWIFT_DIR}" "${OPENCOMBINE_SWIFT_DIR}/*.swift")
list(SORT combine_orig)
file(GLOB combine_patches CONFIGURE_DEPENDS "${COMBINE_PATCH_DIR}/*.patch")
list(SORT combine_patches)

# Sources that are not in the pinned OpenCombine commit (overlays/Combine/Sources, compiled into the framework as they
# are; they get no patches).
file(GLOB COMBINE_EXTRA_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/overlays/Combine/Sources/*.swift")
list(SORT COMBINE_EXTRA_SOURCES)

set(COMBINE_SOURCES)
set(combine_orig_abs)
foreach(rel IN LISTS combine_orig)
	list(APPEND COMBINE_SOURCES "${COMBINE_SOURCE_COPY}/${rel}")
	list(APPEND combine_orig_abs "${OPENCOMBINE_SWIFT_DIR}/${rel}")
endforeach()

set(combine_patch_commands)
foreach(patch IN LISTS combine_patches)
	list(APPEND combine_patch_commands
		COMMAND "${PATCH_PROGRAM}" -p1 -s -d "${COMBINE_SOURCE_COPY}" -i "${patch}")
endforeach()
add_custom_command(
	OUTPUT ${COMBINE_SOURCES}
	COMMAND "${CMAKE_COMMAND}" -E rm -rf "${COMBINE_SOURCE_COPY}"
	COMMAND "${CMAKE_COMMAND}" -E copy_directory "${OPENCOMBINE_SWIFT_DIR}" "${COMBINE_SOURCE_COPY}"
	${combine_patch_commands}
	DEPENDS ${combine_orig_abs} ${combine_patches}
	COMMENT "Applying the Darling patches to the OpenCombine sources"
	VERBATIM
)

# The helpers header is only needed to build the framework: the module imports it implementation-only (patch 0003),
# so clients of Combine do not need the module map.
add_darling_swift_library(Combine
	FRAMEWORK
	SOURCES ${COMBINE_SOURCES} ${COMBINE_EXTRA_SOURCES}
	FLAGS -Xcc -fmodule-map-file=${OPENCOMBINE_HELPERS_INCLUDE}/module.modulemap
	NATIVE_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/overlays/Combine/helpers.c"
	NATIVE_FLAGS -fvisibility=hidden -I${OPENCOMBINE_HELPERS_INCLUDE})
