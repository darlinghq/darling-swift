// Partial CoreText overlay from Apple's public documentation: AdaptiveImageGlyph carries its image content, and the
// metadata members trap because Apple does not document the content format (VibeDarling/darling#845). See README.

// Re-export the CoreText Clang module; without it a Swift module named CoreText hides every C and Objective-C
// declaration behind it (see QuartzCore/QuartzCore.swift for why this is a build flag).
#if DARLING_CORETEXT_CLANG_MODULE
@_exported import CoreText
#endif
@preconcurrency import Foundation
import UniformTypeIdentifiers
package import _DarlingCoreTextShims

extension AttributedString {
	public struct AdaptiveImageGlyph: Hashable, Codable, Sendable {
		public let imageContent: Data

		public init(imageContent: Data) {
			self.imageContent = imageContent
		}

		public var contentIdentifier: String {
			_undocumentedContent("contentIdentifier")
		}

		public var contentDescription: String {
			_undocumentedContent("contentDescription")
		}

		public static var contentType: UTType {
			_undocumentedContent("contentType")
		}

		public init(from decoder: any Decoder) throws {
			imageContent = try decoder.singleValueContainer().decode(Data.self)
		}

		public func encode(to encoder: any Encoder) throws {
			var container = encoder.singleValueContainer()
			try container.encode(imageContent)
		}
	}
}

private func _undocumentedContent(_ member: String) -> Never {
	fatalError("AttributedString.AdaptiveImageGlyph.\(member): Darling cannot read adaptive image glyph content, whose format Apple does not document (VibeDarling/darling#845)")
}

extension CTAdaptiveImageGlyph {
	// Not public API: OpenSwiftUI binds it by its mangled name and declares it itself. Package access keeps it out
	// of clients' name lookup and keeps the shim module off their import path, while still exporting the symbol.
	package static func _adaptiveImageGlyph(convertingFrom adaptiveImageGlyph: AttributedString.AdaptiveImageGlyph) -> CTAdaptiveImageGlyph {
		CTAdaptiveImageGlyph(imageContent: adaptiveImageGlyph.imageContent)
	}
}
