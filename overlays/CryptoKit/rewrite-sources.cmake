# Copyright (C) 2026 Lubos Dolezel
#
# Copies the Swift sources of swift-crypto's Crypto module with the three changes that make them the module CryptoKit
# (see DARLING-CHANGES.md). Run by cryptokit.cmake as a build step:
#
#   cmake -DSOURCE_DIR=<Sources/Crypto of the swift-crypto checkout> -DOUTPUT_DIR=<directory for the copies>
#         -DFILE_LIST=<file with one path relative to SOURCE_DIR per line>
#         -DEXPECTED_GUARDS=<n> -DEXPECTED_QUALIFIERS=<n> -P rewrite-sources.cmake
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
# Any other use of canImport(CryptoKit) on a #if or #elseif line (negated, combined, an #elseif) stops the build, since
# the rewrite would not cover it. The numbers of changes are checked against the swift-crypto tag the lists were made
# for. A source that needs a third kind of change, or one more guard than expected (a bump that adds a file), stops the
# build before any file is written, instead of giving an empty or half-renamed module.

foreach(var SOURCE_DIR OUTPUT_DIR FILE_LIST EXPECTED_GUARDS EXPECTED_QUALIFIERS)
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
	get_filename_component(dir "${OUTPUT_DIR}/${rel}" DIRECTORY)
	file(MAKE_DIRECTORY "${dir}")
	file(WRITE "${OUTPUT_DIR}/${rel}" "${content}")
endforeach()
message(STATUS "CryptoKit sources: ${guards} canImport(CryptoKit) tests, ${qualifiers} qualifiers and "
	"${inlinable_inits} initializers rewritten")
