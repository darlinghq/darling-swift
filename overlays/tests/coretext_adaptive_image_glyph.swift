// CoreText overlay: AttributedString.AdaptiveImageGlyph storage, equality, hashing and Codable, and the conversions
// to and from CTAdaptiveImageGlyph, called through their mangled names as a client that declares them itself does.
// Exits non-zero on failure.

import CoreText
import Foundation
import _DarlingCoreTextShims

var failures = 0
func check(_ ok: Bool, _ what: String) {
	print("\(ok ? "PASS" : "FAIL"): \(what)")
	if !ok { failures += 1 }
}

extension CTAdaptiveImageGlyph {
	@_silgen_name("$sSo20CTAdaptiveImageGlyphC8CoreTextE09_adaptivebC014convertingFromAB10Foundation16AttributedStringVACE08AdaptivebC0V_tFZ")
	static func convertingFromMangledName(_ adaptiveImageGlyph: AttributedString.AdaptiveImageGlyph) -> CTAdaptiveImageGlyph
}

@_silgen_name("$s10Foundation16AttributedStringV8CoreTextE18AdaptiveImageGlyphV15_convertingFromAFSo010CTAdaptivegH0C_tcfC")
func adaptiveImageGlyph(convertingFrom glyph: CTAdaptiveImageGlyph) -> AttributedString.AdaptiveImageGlyph

let content = Data([0, 0, 0, 0x18] + Array("ftypheic".utf8))
let glyph = AttributedString.AdaptiveImageGlyph(imageContent: content)
check(glyph.imageContent == content, "image content round trip")
check(glyph == AttributedString.AdaptiveImageGlyph(imageContent: content), "equal content, equal glyphs")
check(glyph.hashValue == AttributedString.AdaptiveImageGlyph(imageContent: content).hashValue, "equal content, equal hashes")
check(glyph != AttributedString.AdaptiveImageGlyph(imageContent: content + [1]), "different content, different glyphs")
check(Set([glyph, glyph, AttributedString.AdaptiveImageGlyph(imageContent: Data())]).count == 2, "usable in a Set")

do {
	let encoded = try JSONEncoder().encode(glyph)
	check(String(decoding: encoded, as: UTF8.self) == "\"\(content.base64EncodedString(options: []))\"", "Codable writes the image content as one Data value")
	check(try JSONDecoder().decode(AttributedString.AdaptiveImageGlyph.self, from: encoded) == glyph, "Codable round trip")
	let list = try PropertyListEncoder().encode([glyph])
	check(try PropertyListDecoder().decode([AttributedString.AdaptiveImageGlyph].self, from: list) == [glyph], "property list round trip")
} catch {
	check(false, "Codable threw \(error)")
}

let ctGlyph = CTAdaptiveImageGlyph.convertingFromMangledName(glyph)
check(ctGlyph.imageContent == content, "conversion to CTAdaptiveImageGlyph keeps the content")
check(ctGlyph.conforms(to: CTAdaptiveImageProviding.self), "CTAdaptiveImageGlyph provides adaptive images")
check(ctGlyph.isEqual(CTAdaptiveImageGlyph.convertingFromMangledName(glyph)), "conversions of equal glyphs are equal")
check(adaptiveImageGlyph(convertingFrom: ctGlyph) == glyph, "converting back from CTAdaptiveImageGlyph keeps the content")

exit(failures == 0 ? 0 : 1)
