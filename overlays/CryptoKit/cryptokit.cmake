# Copyright (C) 2026 Lubos Dolezel
#
# CryptoKit.framework, built from apple/swift-crypto (Apache-2.0, https://github.com/apple/swift-crypto) as the Swift
# module CryptoKit, so that the mangled names are the ones applications import from Apple's framework. Included from
# the parent CMakeLists.txt when the Swift toolchain was found; overlays/README.md and DARLING-CHANGES.md say what is
# compiled and what is changed.
#
# SWIFT_CRYPTO_SOURCE_DIR is a checkout of swift-crypto at the tag 5.1.2 (the main repository's src/external/swift-crypto
# submodule once the darlinghq/swift-crypto mirror exists). It is never written to: the Swift sources are copied into the
# build directory with the changes of rewrite-sources.cmake. BoringSSL (Sources/CCryptoBoringSSL) and XKCP (Sources/CXKCP)
# are compiled into the framework as they are, with hidden visibility.
#
# DARLING_CRYPTOKIT: ON builds the framework and stops the configuration when there is no checkout, OFF skips it, AUTO
# (the default) builds it when SWIFT_CRYPTO_SOURCE_DIR is a checkout. AUTO and not a boolean option whose default
# depends on the checkout, because such a default is fixed in the cache by the first configuration: a tree configured
# before the submodule existed would never build CryptoKit.

set(DARLING_CRYPTOKIT AUTO CACHE STRING "Build CryptoKit.framework from apple/swift-crypto: ON, OFF, or AUTO (when SWIFT_CRYPTO_SOURCE_DIR is a checkout)")
set_property(CACHE DARLING_CRYPTOKIT PROPERTY STRINGS AUTO ON OFF)
set(SWIFT_CRYPTO_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../swift-crypto" CACHE PATH
	"Checkout of apple/swift-crypto at the tag 5.1.2 (commit 3280a5f72874d2f73bf25551bbb64f524c76d834)")

if (NOT DARLING_CRYPTOKIT MATCHES "^(AUTO|ON|OFF)$")
	message(FATAL_ERROR "DARLING_CRYPTOKIT must be AUTO, ON or OFF, not '${DARLING_CRYPTOKIT}'")
endif()
if (DARLING_CRYPTOKIT STREQUAL "OFF")
	return()
endif()
if (NOT EXISTS "${SWIFT_CRYPTO_SOURCE_DIR}/Package.swift")
	if (DARLING_CRYPTOKIT STREQUAL "ON")
		message(FATAL_ERROR "SWIFT_CRYPTO_SOURCE_DIR (${SWIFT_CRYPTO_SOURCE_DIR}) is not a checkout: fetch the "
			"submodules (git submodule update --init) or point SWIFT_CRYPTO_SOURCE_DIR at a checkout of apple/swift-crypto "
			"at the tag 5.1.2, or configure with -DDARLING_CRYPTOKIT=OFF")
	endif()
	message(STATUS "CryptoKit.framework is not built: SWIFT_CRYPTO_SOURCE_DIR (${SWIFT_CRYPTO_SOURCE_DIR}) is not a "
		"checkout of apple/swift-crypto (DARLING_CRYPTOKIT=AUTO)")
	return()
endif()

include("${CMAKE_CURRENT_SOURCE_DIR}/overlays/CryptoKit/sources.cmake")

set(CRYPTOKIT_OVERLAY_DIR "${CMAKE_CURRENT_SOURCE_DIR}/overlays/CryptoKit")
set(CRYPTOKIT_SOURCES_DIR "${SWIFT_CRYPTO_SOURCE_DIR}/Sources")
set(CRYPTOKIT_BORINGSSL_DIR "${CRYPTOKIT_SOURCES_DIR}/CCryptoBoringSSL")

# _cryptokit_files(<out var> <directory> <file>...): the files with the directory in front. The lists were made for one
# tag, so a file that is not in the checkout stops the configuration with the cause instead of the build with a missing
# rule.
function(_cryptokit_files out dir)
	set(paths)
	foreach(file IN LISTS ARGN)
		if (NOT EXISTS "${dir}/${file}")
			message(FATAL_ERROR "${dir}/${file} is not in SWIFT_CRYPTO_SOURCE_DIR (${SWIFT_CRYPTO_SOURCE_DIR}): it is "
				"not the tag that overlays/CryptoKit/sources.cmake was made for (5.1.2)")
		endif()
		list(APPEND paths "${dir}/${file}")
	endforeach()
	set(${out} ${paths} PARENT_SCOPE)
endfunction()

# The Swift sources of Crypto, copied with the rewrite rules into the build directory. The tests of the rules are the
# numbers: 92 `#if canImport(CryptoKit)` tests and 4 `Crypto.` qualifiers in swift-crypto 5.1.2.
set(CRYPTOKIT_SOURCE_COPY "${CMAKE_CURRENT_BINARY_DIR}/cryptokit-src")
set(CRYPTOKIT_SOURCE_LIST "${CMAKE_CURRENT_BINARY_DIR}/cryptokit-src.txt")
_cryptokit_files(cryptokit_orig "${CRYPTOKIT_SOURCES_DIR}/Crypto" ${SWIFT_CRYPTO_SWIFT_FILES})
set(CRYPTOKIT_WRAPPER_COPY "${CMAKE_CURRENT_BINARY_DIR}/cryptokit-wrapper-src")
set(CRYPTOKIT_WRAPPER_AEAD_COPY "${CRYPTOKIT_WRAPPER_COPY}/AEAD/BoringSSLAEAD.swift")
set(CRYPTOKIT_SWIFT_SOURCES)
foreach(rel IN LISTS SWIFT_CRYPTO_SWIFT_FILES)
	list(APPEND CRYPTOKIT_SWIFT_SOURCES "${CRYPTOKIT_SOURCE_COPY}/${rel}")
endforeach()
list(JOIN SWIFT_CRYPTO_SWIFT_FILES "\n" cryptokit_list_content)
file(GENERATE OUTPUT "${CRYPTOKIT_SOURCE_LIST}" CONTENT "${cryptokit_list_content}\n")
add_custom_command(
	OUTPUT ${CRYPTOKIT_SWIFT_SOURCES} "${CRYPTOKIT_WRAPPER_AEAD_COPY}"
	COMMAND "${CMAKE_COMMAND}" -DSOURCE_DIR=${CRYPTOKIT_SOURCES_DIR}/Crypto -DOUTPUT_DIR=${CRYPTOKIT_SOURCE_COPY}
		-DFILE_LIST=${CRYPTOKIT_SOURCE_LIST} -DEXPECTED_GUARDS=92 -DEXPECTED_QUALIFIERS=4
		-DWRAPPER_SOURCE_DIR=${CRYPTOKIT_SOURCES_DIR}/CryptoBoringWrapper -DWRAPPER_OUTPUT_DIR=${CRYPTOKIT_WRAPPER_COPY}
		-P "${CRYPTOKIT_OVERLAY_DIR}/rewrite-sources.cmake"
	DEPENDS ${cryptokit_orig} "${CRYPTOKIT_SOURCES_DIR}/CryptoBoringWrapper/AEAD/BoringSSLAEAD.swift" "${CRYPTOKIT_SOURCE_LIST}" "${CRYPTOKIT_OVERLAY_DIR}/rewrite-sources.cmake"
	COMMENT "Rewriting the swift-crypto sources into the module CryptoKit"
	VERBATIM
)

# The C modules the Swift sources import. They are found by the module maps of the checkout.
set(CRYPTOKIT_XKCP_DIR "${CRYPTOKIT_SOURCES_DIR}/CXKCP")
set(CRYPTOKIT_XKCP_SHIMS_DIR "${CRYPTOKIT_SOURCES_DIR}/CXKCPShims")
set(cryptokit_c_modules)
foreach(include_dir IN ITEMS "${CRYPTOKIT_BORINGSSL_DIR}/include" "${CRYPTOKIT_XKCP_DIR}/include" "${CRYPTOKIT_XKCP_SHIMS_DIR}/include")
	list(APPEND cryptokit_c_modules -Xcc -fmodule-map-file=${include_dir}/module.modulemap -Xcc -I${include_dir})
endforeach()

# The flags of swift-crypto's Package.swift. Both modules share the package name, because CryptoBoringWrapper declares
# its API with `package` access. -swift-version 6 is the language mode of a package with tools version 6.2; it comes
# after the -swift-version 5 of add_darling_swift_library.
set(cryptokit_swift_flags
	${overlay_shims} ${cryptokit_c_modules}
	-swift-version 6 -package-name com.apple.swift-crypto
	-enable-experimental-feature Lifetimes -enable-experimental-feature SourceWarningControl
	-enable-upcoming-feature MemberImportVisibility)

# CryptoBoringWrapper is an implementation detail of Crypto: compiled without library evolution, linked into the
# framework, and kept out of its export table (unexported.txt).
_cryptokit_files(cryptokit_wrapper_sources "${CRYPTOKIT_SOURCES_DIR}/CryptoBoringWrapper" ${SWIFT_CRYPTO_WRAPPER_FILES})
# AEAD/BoringSSLAEAD.swift is the rewritten copy (rule 4 of rewrite-sources.cmake).
list(REMOVE_ITEM cryptokit_wrapper_sources "${CRYPTOKIT_SOURCES_DIR}/CryptoBoringWrapper/AEAD/BoringSSLAEAD.swift")
list(APPEND cryptokit_wrapper_sources "${CRYPTOKIT_WRAPPER_AEAD_COPY}")
add_darling_swift_object(CryptoBoringWrapper
	SOURCES ${cryptokit_wrapper_sources}
	MODULES Foundation
	FLAGS ${cryptokit_swift_flags})

# Native sources: BoringSSL's C++ and assembly, XKCP's C. The Mach-O assembly files carry an architecture guard each, so
# the whole list can be compiled for every slice and gives an empty object for the slice it is not for.
_cryptokit_files(cryptokit_cxx_sources "${CRYPTOKIT_BORINGSSL_DIR}" ${SWIFT_CRYPTO_BORINGSSL_CXX_FILES})
_cryptokit_files(cryptokit_asm_sources "${CRYPTOKIT_BORINGSSL_DIR}"
	${SWIFT_CRYPTO_BORINGSSL_ASM_COMMON_FILES} ${SWIFT_CRYPTO_BORINGSSL_ASM_X86_64_FILES}
	${SWIFT_CRYPTO_BORINGSSL_ASM_ARM64_FILES})
_cryptokit_files(cryptokit_xkcp_sources "${CRYPTOKIT_XKCP_DIR}" ${SWIFT_CRYPTO_XKCP_FILES})
_cryptokit_files(cryptokit_xkcp_shims_sources "${CRYPTOKIT_XKCP_SHIMS_DIR}" ${SWIFT_CRYPTO_XKCP_SHIMS_FILES})
# Darling compiles arm64 with -mcpu=generic, which defines neither __ARM_FEATURE_AES nor __ARM_FEATURE_SHA2. BoringSSL's
# Apple arm64 startup code (crypto/cpu_aarch64_apple.cc) requires both statically (every Apple arm64 CPU has them), so
# the arm64 slice gets the crypto extension. -Xarch_arm64 keeps the other slices untouched. The arm64 slice then assumes
# the AES and SHA extensions at run time: on a CPU without them it dies with SIGILL.
set(cryptokit_native_flags -fvisibility=hidden -DNDEBUG -Xarch_arm64 -march=armv8-a+crypto
	-I${CRYPTOKIT_BORINGSSL_DIR}/include -I${CRYPTOKIT_XKCP_DIR}/include -I${CRYPTOKIT_XKCP_SHIMS_DIR}/include)

add_darling_swift_library(CryptoKit
	FRAMEWORK
	SOURCES ${CRYPTOKIT_SWIFT_SOURCES}
	MODULES CryptoBoringWrapper Foundation Dispatch CoreFoundation ObjectiveC Darwin
	FLAGS ${cryptokit_swift_flags} -DDARLING_CRYPTOKIT_MODULE
	OBJECTS "${CryptoBoringWrapper_OBJECT}"
	NATIVE_SOURCES ${cryptokit_cxx_sources} ${cryptokit_asm_sources} ${cryptokit_xkcp_sources}
		${cryptokit_xkcp_shims_sources}
	NATIVE_FLAGS ${cryptokit_native_flags}
	INSTALL_NAME "/System/Library/Frameworks/CryptoKit.framework/Versions/A/CryptoKit"
	LINK_FLAGS -Wl,-unexported_symbols_list,${CRYPTOKIT_OVERLAY_DIR}/unexported.txt
	LIBRARIES Foundation CoreFoundation)
set_property(TARGET swiftCryptoKit APPEND PROPERTY LINK_DEPENDS "${CRYPTOKIT_OVERLAY_DIR}/unexported.txt")

# add_darling_swift_library gives every native source the same flags. -std=c++17 is not valid for C and assembly, so the
# C++ files get theirs here, which replaces the property set by the call. BoringSSL's C++ is written for no exceptions
# and no RTTI: the framework must not need the C++ runtime.
string(REPLACE ";" " " cryptokit_native_flag_string "${cryptokit_native_flags}")
set_source_files_properties(${cryptokit_cxx_sources} PROPERTIES
	COMPILE_FLAGS "-std=c++17 -fno-exceptions -fno-rtti ${cryptokit_native_flag_string}")
