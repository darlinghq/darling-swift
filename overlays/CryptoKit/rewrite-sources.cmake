# Copyright (C) 2026 Lubos Dolezel
#
# Copies the Swift sources of swift-crypto's Crypto module with the three changes that make them the module CryptoKit
# (see DARLING-CHANGES.md). Run by cryptokit.cmake as a build step:
#
#   cmake -DSOURCE_DIR=<Sources/Crypto of the swift-crypto checkout> -DOUTPUT_DIR=<directory for the copies>
#         -DFILE_LIST=<file with one path relative to SOURCE_DIR per line>
#         -DEXPECTED_GUARDS=<n> -DEXPECTED_QUALIFIERS=<n>
#         -DWRAPPER_SOURCE_DIR=<Sources/CryptoBoringWrapper> -DWRAPPER_OUTPUT_DIR=<directory for the copy>
#         -P rewrite-sources.cmake
#
# 1. Every `#if canImport(CryptoKit)` becomes `#if canImport(CryptoKit) && !DARLING_CRYPTOKIT_MODULE`. swift-crypto
#    wraps each of its API files in that test and re-exports Apple's CryptoKit when it is true, and the module being
#    compiled is itself named CryptoKit. cryptokit.cmake defines DARLING_CRYPTOKIT_MODULE, so the implementation in
#    the #else branch is compiled.
# 2. `Crypto.` before a capital letter, not preceded by an identifier or a dot, becomes `CryptoKit.`: swift-crypto
#    qualifies four names with its module name.
# 3. Three initializers that are `@inlinable` become `@usableFromInline`. The module is built
#    with library evolution, and an `@inlinable` initializer of a struct that is not `@frozen` may not assign a stored
#    property (`self.x = ...`) there: "'self' used before 'self.init' call or assignment to 'self'". Each initializer
#    is named by file and exact text and must occur exactly once. The body then stays in the framework instead of
#    being emitted into clients.
#
# 4. In the CryptoBoringWrapper file AEAD/BoringSSLAEAD.swift (copied to WRAPPER_OUTPUT_DIR; the other wrapper files are
#    compiled from the checkout), the two places that throw for a failed AEAD open call a new helper,
#    failedAEADOpenError(), which is appended to the copy. It returns CryptoBoringWrapperError.authenticationFailure
#    when the newest BoringSSL error is a cipher bad-decrypt error (the failure of a tag, whose check BoringSSL
#    reports like that for AES-GCM and ChaCha20-Poly1305) and otherwise the error that was thrown before
#    (internalBoringSSLError()), so other failures keep their mapping. The wrapper cannot name CryptoKitError, so:
# 5. In Crypto's AEADs/ChachaPoly/BoringSSL/ChaChaPoly_boring.swift, the two `open` wrappers (shared by AES.GCM and
#    ChaChaPoly) that already turn the wrapper's underlyingCoreCryptoError into CryptoKitError also turn
#    authenticationFailure into CryptoKitError.authenticationFailure, the error that CryptoKit throws for a failed
#    open. swift-crypto does not need this itself: on Apple platforms it re-exports Apple's CryptoKit, and the BoringSSL
#    code paths only run on other platforms, where they report the raw BoringSSL error.
#
# 6. In Util/Backports.swift, `#if compiler(<6.4)` becomes `#if true`. That file gives ContiguousBytes.withBytes and the
#    MutableRawSpan byte subscript to a toolchain older than Swift 6.4, which supplies both itself. CryptoKit is not
#    compiled against the toolchain's own Foundation and standard library but against the Darling SDK's modules (the
#    Foundation overlay, built from swift-foundation at swift-6.3.3-RELEASE, and the standard library module
#    interfaces in stdlib-modules), whatever compiler builds them, and those have neither API. So the shims are needed with every
#    toolchain: without the rewrite a Swift 6.4 build stops at "value of type 'H.Digest' has no member 'withBytes'".
#    The declarations stay internal to CryptoKit and add nothing to the framework's or the overlays' public API.
#
# Any other use of canImport(CryptoKit) on a #if or #elseif line (negated, combined, an #elseif) stops the build, since
# the rewrite would not cover it. The numbers of changes are checked against the swift-crypto tag the lists were made
# for. A source that needs a third kind of change, or one more guard than expected (a bump that adds a file), stops the
# build before any file is written, instead of giving an empty or half-renamed module.

foreach(var SOURCE_DIR OUTPUT_DIR FILE_LIST EXPECTED_GUARDS EXPECTED_QUALIFIERS WRAPPER_SOURCE_DIR WRAPPER_OUTPUT_DIR)
	if (NOT DEFINED ${var})
		message(FATAL_ERROR "rewrite-sources.cmake: ${var} is not set")
	endif()
endforeach()

set(guard "#if canImport(CryptoKit)")
set(guard_regex "#if canImport\\(CryptoKit\\)")
# Every use of canImport(CryptoKit) on a #if or #elseif line, whatever else the line says (`#if !canImport(CryptoKit)`,
# `#elseif canImport(CryptoKit)`). A `#endif // canImport(CryptoKit)` comment is not one.
set(directive_line_regex "(^|\n)[ \t]*#[ \t]*(if|elseif)[^\n]*")
set(directive_use_regex "canImport[ \t]*\\([ \t]*CryptoKit")
set(qualifier_regex "(^|[^A-Za-z0-9_.])Crypto\\.([A-Z])")

# The initializers of rule 3: a file of the list, and the text that starts the initializer, up to and including the
# line that assigns the stored property. The same text for the two Curve25519 public keys.
set(inlinable_init_files
	"Keys/EC/BoringSSL/Ed25519_boring.swift"
	"Keys/EC/BoringSSL/X25519Keys_boring.swift"
	"Keys/EC/BoringSSL/NISTCurvesKeys_boring.swift")
set(curve25519_init "@inlinable\n        init<D: ContiguousBytes>(rawRepresentation: D) throws {\n            self.keyBytes = try rawRepresentation.withUnsafeBytes {")
set(nist_init "@inlinable\n    init(wrapping key: BoringSSLECPublicKeyWrapper<Curve>) {\n        self.key = key\n    }")
set(inlinable_init_texts "${curve25519_init}" "${curve25519_init}" "${nist_init}")

# Rule 4: the wrapper file, the texts of the two failed-open sites and the helper appended to the file. Each site text
# must occur exactly once. The first is the in-place open (open_gather into the message), the second the open that
# allocates the output.
set(wrapper_file "AEAD/BoringSSLAEAD.swift")
set(open_site_in_place "guard rc == 1 else {\n            throw CryptoBoringWrapperError.internalBoringSSLError()\n        }\n    }\n\n    /// The unsafe base call: not inlinable so that it can touch private variables.\n    @usableFromInline\n    func _openContiguous(\n        ciphertext: RawSpan,")
set(open_site_allocating "free(outputBuffer.baseAddress)\n            throw CryptoBoringWrapperError.internalBoringSSLError()")
set(failed_open_helper "
@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, macCatalyst 13, visionOS 1.0, *)
extension CryptoBoringWrapperError {
    /// The error for a failed AEAD open call: the tag did not authenticate when BoringSSL's newest error is the
    /// bad-decrypt error of the cipher library, anything else keeps the generic mapping.
    static func failedAEADOpenError() -> CryptoBoringWrapperError {
        let code = CCryptoBoringSSL_ERR_peek_last_error()
        if CCryptoBoringSSL_ERR_GET_LIB(code) == ERR_LIB_CIPHER && CCryptoBoringSSL_ERR_GET_REASON(code) == CIPHER_R_BAD_DECRYPT {
            CCryptoBoringSSL_ERR_clear_error()
            return .authenticationFailure
        }
        return .internalBoringSSLError()
    }
}
")
# Rule 5: the `open` wrappers of ChaChaPoly_boring.swift: the call up to the catch of underlyingCoreCryptoError.
set(crypto_open_file "AEADs/ChachaPoly/BoringSSL/ChaChaPoly_boring.swift")
set(crypto_open_regex "(context\\.open\\([^}]*\\)\n        )(\\} catch CryptoBoringWrapperError\\.underlyingCoreCryptoError)")
set(crypto_open_replacement "\\1} catch CryptoBoringWrapperError.authenticationFailure {\n            throw CryptoKitError.authenticationFailure\n        \\2")

# Rule 6: the file and the guard line that is made unconditional.
set(backports_file "Util/Backports.swift")
set(backports_guard "#if compiler(<6.4)\n")

# The number of times `needle` occurs in `text`, without regular expressions.
function(_count_occurrences text needle out)
	string(LENGTH "${needle}" needle_length)
	string(LENGTH "${text}" length_before)
	string(REPLACE "${needle}" "" stripped "${text}")
	string(LENGTH "${stripped}" length_after)
	math(EXPR occurrences "(${length_before} - ${length_after}) / ${needle_length}")
	set(${out} ${occurrences} PARENT_SCOPE)
endfunction()

file(STRINGS "${FILE_LIST}" files)
set(guards 0)
set(qualifiers 0)
set(exported_imports 0)
foreach(rel IN LISTS files)
	file(READ "${SOURCE_DIR}/${rel}" content)
	string(REGEX MATCHALL "${guard_regex}" found "${content}")
	list(LENGTH found file_guards)
	string(REGEX MATCHALL "${directive_line_regex}" found_lines "${content}")
	string(REGEX MATCHALL "${directive_use_regex}" found "${found_lines}")
	list(LENGTH found file_directive_uses)
	if (NOT file_directive_uses EQUAL file_guards)
		message(FATAL_ERROR "${rel}: ${file_directive_uses} uses of canImport(CryptoKit) on #if or #elseif lines, "
			"${file_guards} of them the plain `#if canImport(CryptoKit)` that is rewritten. Another form needs a rule "
			"in overlays/CryptoKit/rewrite-sources.cmake.")
	endif()
	string(REGEX MATCHALL "${guard_regex}\n" found_whole_line "${content}")
	list(LENGTH found_whole_line file_whole_line_guards)
	if (NOT file_guards EQUAL file_whole_line_guards)
		message(FATAL_ERROR "${rel}: a canImport(CryptoKit) test that is not alone on its line")
	endif()
	string(REGEX MATCHALL "${qualifier_regex}" found "${content}")
	list(LENGTH found file_qualifiers)
	string(REGEX MATCHALL "@_exported import CryptoKit" found "${content}")
	list(LENGTH found file_exports)
	math(EXPR guards "${guards} + ${file_guards}")
	math(EXPR qualifiers "${qualifiers} + ${file_qualifiers}")
	math(EXPR exported_imports "${exported_imports} + ${file_exports}")
endforeach()
if (NOT guards EQUAL EXPECTED_GUARDS OR NOT qualifiers EQUAL EXPECTED_QUALIFIERS OR NOT exported_imports EQUAL guards)
	message(FATAL_ERROR "found ${guards} canImport(CryptoKit) tests, ${qualifiers} Crypto. qualifiers and "
		"${exported_imports} re-exports of CryptoKit in ${SOURCE_DIR}; expected ${EXPECTED_GUARDS} tests, "
		"${EXPECTED_QUALIFIERS} qualifiers and as many re-exports as tests. Is the checkout the tag the file lists "
		"were made for? The rules in overlays/CryptoKit/rewrite-sources.cmake need review.")
endif()

list(LENGTH inlinable_init_files inlinable_inits)
math(EXPR last_init "${inlinable_inits} - 1")
foreach(index RANGE ${last_init})
	list(GET inlinable_init_files ${index} init_file)
	list(GET inlinable_init_texts ${index} init_text)
	list(FIND files "${init_file}" init_in_list)
	if (init_in_list EQUAL -1)
		message(FATAL_ERROR "${init_file} is not in ${FILE_LIST}, but rule 3 of "
			"overlays/CryptoKit/rewrite-sources.cmake rewrites an initializer in it")
	endif()
	file(READ "${SOURCE_DIR}/${init_file}" content)
	_count_occurrences("${content}" "${init_text}" found_inits)
	if (NOT found_inits EQUAL 1)
		message(FATAL_ERROR "${init_file}: expected the @inlinable initializer rewritten by rule 3 once, found "
			"${found_inits} times. Is the checkout the tag the rule was made for? The rule needs review.")
	endif()
endforeach()

list(FIND files "${crypto_open_file}" crypto_open_in_list)
if (crypto_open_in_list EQUAL -1)
	message(FATAL_ERROR "${crypto_open_file} is not in ${FILE_LIST}, but rule 5 of "
		"overlays/CryptoKit/rewrite-sources.cmake rewrites it")
endif()
file(READ "${SOURCE_DIR}/${crypto_open_file}" content)
string(REGEX MATCHALL "${crypto_open_regex}" found "${content}")
list(LENGTH found found_crypto_opens)
if (NOT found_crypto_opens EQUAL 2)
	message(FATAL_ERROR "${crypto_open_file}: expected two open wrappers rewritten by rule 5, found "
		"${found_crypto_opens}. Is the checkout the tag the rule was made for? The rule needs review.")
endif()
list(FIND files "${backports_file}" backports_in_list)
if (backports_in_list EQUAL -1)
	message(FATAL_ERROR "${backports_file} is not in ${FILE_LIST}, but rule 6 of "
		"overlays/CryptoKit/rewrite-sources.cmake rewrites it")
endif()
file(READ "${SOURCE_DIR}/${backports_file}" content)
_count_occurrences("${content}" "${backports_guard}" found_backports_guards)
if (NOT found_backports_guards EQUAL 1)
	message(FATAL_ERROR "${backports_file}: expected the guard of rule 6 once, found ${found_backports_guards} "
		"times. Is the checkout the tag the rule was made for? The rule needs review.")
endif()
file(READ "${WRAPPER_SOURCE_DIR}/${wrapper_file}" wrapper_content)
foreach(site IN ITEMS open_site_in_place open_site_allocating)
	_count_occurrences("${wrapper_content}" "${${site}}" found_sites)
	if (NOT found_sites EQUAL 1)
		message(FATAL_ERROR "${wrapper_file}: expected the failed-open site '${site}' of rule 4 once, found "
			"${found_sites} times. Is the checkout the tag the rule was made for? The rule needs review.")
	endif()
endforeach()

foreach(rel IN LISTS files)
	file(READ "${SOURCE_DIR}/${rel}" content)
	string(REPLACE "${guard}" "${guard} && !DARLING_CRYPTOKIT_MODULE" content "${content}")
	string(REGEX REPLACE "${qualifier_regex}" "\\1CryptoKit.\\2" content "${content}")
	foreach(index RANGE ${last_init})
		list(GET inlinable_init_files ${index} init_file)
		if (rel STREQUAL init_file)
			list(GET inlinable_init_texts ${index} init_text)
			string(REPLACE "@inlinable" "@usableFromInline" init_replacement "${init_text}")
			string(REPLACE "${init_text}" "${init_replacement}" content "${content}")
		endif()
	endforeach()
	if (rel STREQUAL crypto_open_file)
		string(REGEX REPLACE "${crypto_open_regex}" "${crypto_open_replacement}" content "${content}")
	endif()
	if (rel STREQUAL backports_file)
		string(REPLACE "${backports_guard}" "#if true\n" content "${content}")
	endif()
	get_filename_component(dir "${OUTPUT_DIR}/${rel}" DIRECTORY)
	file(MAKE_DIRECTORY "${dir}")
	file(WRITE "${OUTPUT_DIR}/${rel}" "${content}")
endforeach()
foreach(site IN ITEMS open_site_in_place open_site_allocating)
	string(REPLACE "CryptoBoringWrapperError.internalBoringSSLError()" "CryptoBoringWrapperError.failedAEADOpenError()"
		site_replacement "${${site}}")
	string(REPLACE "${${site}}" "${site_replacement}" wrapper_content "${wrapper_content}")
endforeach()
get_filename_component(wrapper_dir "${WRAPPER_OUTPUT_DIR}/${wrapper_file}" DIRECTORY)
file(MAKE_DIRECTORY "${wrapper_dir}")
file(WRITE "${WRAPPER_OUTPUT_DIR}/${wrapper_file}" "${wrapper_content}${failed_open_helper}")
message(STATUS "CryptoKit sources: ${guards} canImport(CryptoKit) tests, ${qualifiers} qualifiers and "
	"${inlinable_inits} initializers rewritten")
