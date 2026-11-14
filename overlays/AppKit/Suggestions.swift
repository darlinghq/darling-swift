// The NSTextField suggestions API (macOS 15). The types are plain values and a protocol; nothing calls the delegate
// yet, the text field only stores it.
//
// Provenance. Names: imported by Notes and Photos (rung 5, llvm-nm -u -m). Declarations, generic parameters and the
// documented members: Apple's public documentation, https://developer.apple.com/documentation/appkit/
// nssuggestionitem, nssuggestionitemsection, nssuggestionitemresponse, nstextsuggestionsdelegate (a class-bound
// `@MainActor` protocol with one associated type and the `Item`, `ItemResponse` and `ItemSection` aliases; the two
// optional methods have default implementations, and the page for `textField(_:didSelect:)` says its default inserts
// the `textField(_:textCompletionFor:)` text into the control) and nstextfield/suggestionsdelegate.
// Layout that cannot matter, by reasoning rather than a source (NEEDS-REAL-MAC whether Apple froze them): the structs and
// the `Phase` enum are built with library evolution, and the demanded names are accessors, an initializer and the enum case
// constructor, which an app only needs if it reaches them through the library rather than inline.
// GUESS (no public source): the declaration order of the three protocol requirements (it fixes the witness-table
// layout; nothing in this overlay calls through it, an app's conformance is only stored), the declaration order of
// the Phase cases, the default `textField(_:textCompletionFor:)` (documented to exist, not to return `title`), and
// that `init(items:)` makes one untitled section.
// Left out because no named app imports them: `secondaryTitle`, `toolTip` and the attributed titles of the item,
// `Equatable` and `Hashable` on all three structs, `preferredHighlight`, and the `appending(_:)` methods.

@_exported import Foundation
#if DARLING_APPKIT_CLANG_MODULE
@_exported import AppKit
#else
import _DarlingAppKitShims
#endif
import ObjectiveC

/// One suggestion shown in a text field's suggestions list.
public struct NSSuggestionItem<SuggestionItemType> {
    /// The text shown for the suggestion.
    public var title: String

    /// An optional image shown beside the title.
    public var image: NSImage?

    /// The value the suggestion stands for, handed back to the delegate on selection.
    public let representedValue: SuggestionItemType

    public init(representedValue: SuggestionItemType, title: String) {
        self.representedValue = representedValue
        self.title = title
    }
}

/// A titled group of suggestions.
public struct NSSuggestionItemSection<SuggestionItemType> {
    public typealias Item = NSSuggestionItem<SuggestionItemType>

    public var title: String?
    public var items: [Item]

    public init(items: [Item]) {
        self.title = nil
        self.items = items
    }

    public init(title: String?, items: [Item]) {
        self.title = title
        self.items = items
    }
}

/// The delegate's answer to a request for suggestions.
public struct NSSuggestionItemResponse<SuggestionItemType> {
    public typealias Item = NSSuggestionItem<SuggestionItemType>
    public typealias ItemSection = NSSuggestionItemSection<SuggestionItemType>

    /// Whether the response is a first approximation or the complete list.
    public enum Phase {
        /// More suggestions may follow.
        case intermediate
        /// The complete list.
        case final
    }

    public var phase: Phase = .final
    public var itemSections: [ItemSection]

    public init() {
        itemSections = []
    }

    /// A response holding `items` in one untitled section.
    public init(items: [Item]) {
        itemSections = [ItemSection(items: items)]
    }

    public init(itemSections: [ItemSection]) {
        self.itemSections = itemSections
    }
}

/// Supplies suggestions to an `NSTextField` and learns which the user picked.
@MainActor
public protocol NSTextSuggestionsDelegate<SuggestionItemType>: AnyObject {
    associatedtype SuggestionItemType

    typealias Item = NSSuggestionItem<SuggestionItemType>
    typealias ItemResponse = NSSuggestionItemResponse<SuggestionItemType>
    typealias ItemSection = NSSuggestionItemSection<SuggestionItemType>

    /// Asks for suggestions for the field's current text; call `responseHandler` with the result.
    func textField(_ textField: NSTextField,
                   provideUpdatedSuggestions responseHandler: @escaping (NSSuggestionItemResponse<SuggestionItemType>) -> Void)

    /// The text to complete the field with for `item`; `nil` leaves the text alone.
    func textField(_ textField: NSTextField, textCompletionFor item: NSSuggestionItem<SuggestionItemType>) -> String?

    /// Called when the user chooses `item`.
    func textField(_ textField: NSTextField, didSelect item: NSSuggestionItem<SuggestionItemType>)
}

extension NSTextSuggestionsDelegate {
    public func textField(_ textField: NSTextField, textCompletionFor item: NSSuggestionItem<SuggestionItemType>) -> String? {
        return item.title
    }

    public func textField(_ textField: NSTextField, didSelect item: NSSuggestionItem<SuggestionItemType>) {
        if let completion = self.textField(textField, textCompletionFor: item) {
            textField.stringValue = completion
        }
    }
}

// A weak box: delegates are not retained, and a Swift existential cannot be stored in an Objective-C property.
private final class SuggestionsDelegateBox {
    weak var delegate: AnyObject?
    @MainActor var suggestions: (any NSTextSuggestionsDelegate)? { return delegate as? any NSTextSuggestionsDelegate }
    init(_ delegate: AnyObject?) { self.delegate = delegate }
}

private var suggestionsDelegateKey: UInt8 = 0

extension NSTextField {
    /// The object asked for suggestions while the user types. Held weakly.
    @MainActor public var suggestionsDelegate: (any NSTextSuggestionsDelegate)? {
        get {
            return (objc_getAssociatedObject(self, &suggestionsDelegateKey) as? SuggestionsDelegateBox)?.suggestions
        }
        set {
            objc_setAssociatedObject(self, &suggestionsDelegateKey, SuggestionsDelegateBox(newValue),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
