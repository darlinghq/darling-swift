// The NSTextField suggestions API (macOS 15). The types are plain values and a protocol; nothing calls the delegate
// yet, the text field only stores it.
//
// Provenance. Declarations, generic parameters and members: Apple's public documentation,
// https://developer.apple.com/documentation/appkit/nssuggestionitem, nssuggestionitemsection,
// nssuggestionitemresponse, nstextsuggestionsdelegate and nstextfield/suggestionsdelegate, compared with the macOS 26
// SDK's Swift module interface (declarations only: the member list, the generic constraints, the declaration order of
// the three protocol requirements and of the Phase and Highlight cases, the @MainActor protocol with the `Item`,
// `ItemResponse` and `ItemSection` aliases). Behaviour (black-box probe on macOS 26.7.3): a response made with
// `init()`, `init(items:)` or `init(itemSections:)` has phase `.final` and highlight `.automatic`, `init(items:)` makes one
// untitled section, the default `textField(_:textCompletionFor:)` returns the item's title, the default
// `textField(_:didSelect:)` sets the field's string to that completion, and the field holds its delegate weakly.
// Equality of items compares the represented value, the titles and the tooltip but not the image; responses compare
// their phase, highlight and sections.
// Not provided: the `appending(_:)` combinators of NSTextSuggestionsDelegate, and the field never calls the delegate.

@_exported import Foundation
import ObjectiveC

/// One suggestion shown in a text field's suggestions list.
public struct NSSuggestionItem<SuggestionItemType> {
    public var representedValue: SuggestionItemType

    /// The text shown for the suggestion; setting it replaces `attributedTitle`.
    public var title: String {
        get { return String(attributedTitle.characters) }
        set { attributedTitle = AttributedString(newValue) }
    }

    public var attributedTitle: AttributedString

    public var secondaryTitle: String? {
        get { return attributedSecondaryTitle.map { String($0.characters) } }
        set { attributedSecondaryTitle = newValue.map { AttributedString($0) } }
    }

    public var attributedSecondaryTitle: AttributedString?

    public var toolTip: String?

    /// An optional image shown beside the title.
    public var image: NSImage?

    public init(representedValue: SuggestionItemType, title: String) {
        self.representedValue = representedValue
        self.attributedTitle = AttributedString(title)
    }

    public init(representedValue: SuggestionItemType, attributedTitle: AttributedString) {
        self.representedValue = representedValue
        self.attributedTitle = attributedTitle
    }
}

extension NSSuggestionItem: Equatable where SuggestionItemType: Equatable {
    public static func == (lhs: NSSuggestionItem<SuggestionItemType>, rhs: NSSuggestionItem<SuggestionItemType>) -> Bool {
        return lhs.representedValue == rhs.representedValue && lhs.attributedTitle == rhs.attributedTitle
            && lhs.attributedSecondaryTitle == rhs.attributedSecondaryTitle && lhs.toolTip == rhs.toolTip
    }
}

extension NSSuggestionItem: Hashable where SuggestionItemType: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(representedValue)
        hasher.combine(attributedTitle)
        hasher.combine(attributedSecondaryTitle)
        hasher.combine(toolTip)
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

extension NSSuggestionItemSection: Equatable where SuggestionItemType: Equatable {}
extension NSSuggestionItemSection: Hashable where SuggestionItemType: Hashable {}

/// The delegate's answer to a request for suggestions.
public struct NSSuggestionItemResponse<SuggestionItemType> {
    public typealias Item = NSSuggestionItem<SuggestionItemType>
    public typealias ItemSection = NSSuggestionItemSection<SuggestionItemType>

    public var itemSections: [ItemSection]

    /// Whether the response is a first approximation or the complete list.
    public enum Phase: Equatable, Hashable {
        /// More suggestions may follow.
        case intermediate
        /// The complete list.
        case final
    }

    public var phase: Phase = .final

    public enum Highlight: Equatable, Hashable {
        case automatic
        case firstSelectableItem
    }

    public var preferredHighlight: Highlight = .automatic

    public init(itemSections: [ItemSection]) {
        self.itemSections = itemSections
    }

    /// A response holding `items` in one untitled section.
    public init(items: [Item]) {
        itemSections = [ItemSection(items: items)]
    }

    public init() {
        itemSections = []
    }
}

extension NSSuggestionItemResponse: Equatable where SuggestionItemType: Equatable {
    public static func == (lhs: NSSuggestionItemResponse<SuggestionItemType>, rhs: NSSuggestionItemResponse<SuggestionItemType>) -> Bool {
        return lhs.itemSections == rhs.itemSections && lhs.phase == rhs.phase && lhs.preferredHighlight == rhs.preferredHighlight
    }
}

extension NSSuggestionItemResponse: Hashable where SuggestionItemType: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(itemSections)
        hasher.combine(phase)
        hasher.combine(preferredHighlight)
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

    /// The text to complete the field with for `item`; the default is the item's title.
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
            // Key-value coding: Darling's NSControl declares -setStringValue: without the property.
            textField.setValue(completion, forKey: "stringValue")
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
