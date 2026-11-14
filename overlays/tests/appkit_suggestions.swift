// NSSuggestionItem, NSSuggestionItemResponse and NSTextSuggestionsDelegate from the AppKit overlay, under Darling.
import AppKit
import _DarlingAppKitShims

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

final class Delegate: NSTextSuggestionsDelegate {
    var selected: [Int] = []
    func textField(_ textField: NSTextField, provideUpdatedSuggestions responseHandler: @escaping (NSSuggestionItemResponse<Int>) -> Void) {
        responseHandler(NSSuggestionItemResponse(items: [NSSuggestionItem(representedValue: 7, title: "seven")]))
    }
    func textField(_ textField: NSTextField, textCompletionFor item: NSSuggestionItem<Int>) -> String? { return "completion" }
    func textField(_ textField: NSTextField, didSelect item: NSSuggestionItem<Int>) { selected.append(item.representedValue) }
}

// The aliases the documentation shows (`Item`, `ItemResponse`, `ItemSection`).
final class Aliased: NSTextSuggestionsDelegate {
    typealias SuggestionItemType = Int
    func textField(_ textField: NSTextField, provideUpdatedSuggestions responseHandler: @escaping (ItemResponse) -> Void) {
        let item = Item(representedValue: 3, title: "three")
        responseHandler(ItemResponse(itemSections: [ItemSection(title: "numbers", items: [item])]))
    }
}

// A delegate that implements only the one required method gets both documented defaults.
final class Minimal: NSTextSuggestionsDelegate {
    func textField(_ textField: NSTextField, provideUpdatedSuggestions responseHandler: @escaping (NSSuggestionItemResponse<String>) -> Void) {}
}

// The delegate protocol is @MainActor, like Apple's; the checks run isolated to the main actor.
MainActor.assumeIsolated {
    var item = NSSuggestionItem(representedValue: 42, title: "answer")
    check(item.representedValue == 42 && item.image == nil, "item")

    var response = NSSuggestionItemResponse<Int>()
    check(response.phase == .final, "phase defaults to final")
    response = NSSuggestionItemResponse(items: [item])
    check(response.phase == .final, "items init keeps the default phase")
    response.phase = .intermediate
    check(response.phase == .intermediate && NSSuggestionItemResponse<Int>.Phase.final != response.phase, "phase")

    let section = NSSuggestionItemSection(title: "Fruit", items: [item])
    check(section.title == "Fruit" && section.items.count == 1 && section.items[0].representedValue == 42, "section")
    check(NSSuggestionItemSection(items: [item]).title == nil, "section without a title")
    var sectioned = NSSuggestionItemResponse(itemSections: [section, NSSuggestionItemSection(items: [])])
    check(sectioned.itemSections.count == 2 && sectioned.phase == .final, "response from sections")
    check(response.itemSections.count == 1 && response.itemSections[0].title == nil && response.itemSections[0].items.count == 1,
          "items init makes one untitled section")
    check(NSSuggestionItemResponse<Int>().itemSections.isEmpty, "empty response has no sections")
    check(item.title == "answer", "item title")

    var aliased: [NSSuggestionItemResponse<Int>] = []
    Aliased().textField(NSTextField(), provideUpdatedSuggestions: { aliased.append($0) })
    check(aliased.count == 1 && aliased[0].itemSections[0].title == "numbers" && aliased[0].itemSections[0].items[0].representedValue == 3,
          "the Item, ItemResponse and ItemSection aliases")

    let minimal = Minimal()
    let stringItem = NSSuggestionItem(representedValue: "k", title: "Applesauce")
    check(minimal.textField(NSTextField(), textCompletionFor: stringItem) == "Applesauce", "default completion is the title")
    let target = NSTextField()
    target.stringValue = "apple"
    minimal.textField(target, didSelect: stringItem)
    check(target.stringValue == "Applesauce", "default selection replaces the field text with the completion")

    let delegate = Delegate()
    var delivered = 0
    delegate.textField(NSTextField(), provideUpdatedSuggestions: { _ in delivered += 1 })
    check(delivered == 1, "the delegate answers through the response handler")
    check(delegate.textField(NSTextField(), textCompletionFor: item) == "completion", "completion")
    delegate.textField(NSTextField(), didSelect: item)
    check(delegate.selected == [42], "selection")

    let field = NSTextField()
    check(field.suggestionsDelegate == nil, "no delegate at first")
    field.suggestionsDelegate = delegate
    check(field.suggestionsDelegate === delegate, "delegate is stored")
    do {
        let transient = Delegate()
        field.suggestionsDelegate = transient
    }
    check(field.suggestionsDelegate == nil, "delegate is not retained")
}

if failures != 0 { exit(1) }
