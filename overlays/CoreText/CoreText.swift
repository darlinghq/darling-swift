// Partial CoreText overlay from Apple's public documentation: AttributedString.AdaptiveImageGlyph carries its image
// content, and CTAdaptiveImageGlyph (a class CoreText keeps private) converts from it. Not included: the glyph's
// contentIdentifier, contentDescription and contentType, whose content format is not documented; see README.

// Re-export the CoreText Clang module; without it a Swift module named CoreText hides every C and Objective-C
// declaration behind it.
@_exported import CoreText
@preconcurrency import Foundation
package import _DarlingCoreTextShims

extension AttributedString {
	public struct AdaptiveImageGlyph: Hashable, Codable, Sendable {
		public let imageContent: Data

		public init(imageContent: Data) {
			self.imageContent = imageContent
		}

		public init(from decoder: any Decoder) throws {
			imageContent = try decoder.singleValueContainer().decode(Data.self)
		}

		public func encode(to encoder: any Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode(imageContent)
		}

		// Not public API: exported for clients that bind the conversion by its mangled name.
		package init(_convertingFrom glyph: CTAdaptiveImageGlyph) {
			imageContent = glyph.imageContent
		}
	}
}

extension CTAdaptiveImageGlyph {
	// Not public API: exported for clients that bind it by its mangled name and declare it themselves. Package access
	// keeps it out of clients' name lookup and keeps the shim module off their import path, while still exporting the
	// symbol.
	package static func _adaptiveImageGlyph(convertingFrom adaptiveImageGlyph: AttributedString.AdaptiveImageGlyph) -> CTAdaptiveImageGlyph {
		CTAdaptiveImageGlyph(imageContent: adaptiveImageGlyph.imageContent)
	}
}
