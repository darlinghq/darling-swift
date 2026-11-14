// NSPopUpButton.init(image:pullDownMenu:) and init(title:image:pullDownMenu:) through the AppKit overlay, under
// Darling. Build with -import-objc-header tests/appkit_popupbutton.h. The expected values are what a real Mac does
// (probe symbols_b_probe1.txt lines 17-18): pull-down, the caller's menu untouched (same object, same items, first item
// still "first"), title "" for the image-only form and "T" for the title form, titleOfSelectedItem "first"; an empty
// menu stays empty with titleOfSelectedItem nil.
import AppKit
import _DarlingAppKitShims

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

func itemTitle(_ menu: NSMenu, _ index: Int) -> String? {
    return (menu.item(at: index) as? NSObject)?.value(forKey: "title") as? String
}

func makeMenu() -> NSMenu {
    let menu = NSMenu(title: "Actions")
    _ = menu.addItem(withTitle: "first", action: nil, keyEquivalent: "")
    _ = menu.addItem(withTitle: "second", action: nil, keyEquivalent: "")
    return menu
}

let image = NSImage(size: NSSize(width: 4, height: 4))

let imageMenu = makeMenu()
let withImage = NSPopUpButton(image: image, pullDownMenu: imageMenu)
check(withImage.pullsDown, "init(image:pullDownMenu:) makes a pull-down button")
check(withImage.menu === imageMenu, "the menu is the caller's object")
check(imageMenu.numberOfItems == 2 && itemTitle(imageMenu, 0) == "first" && itemTitle(imageMenu, 1) == "second",
      "the menu keeps its two items, the first still titled \"first\"")
check(withImage.title == "", "the image-only form has an empty title")
check(withImage.titleOfSelectedItem == "first", "titleOfSelectedItem is the first item's title")
// Darling's NSPopUpButtonCell ignores -setImage: (see PopUpButton.swift), so `image === image` and usesItemFromMenu
// (both observed on the Mac) cannot be asserted here.

let titleMenu = makeMenu()
let titled = NSPopUpButton(title: "T", image: nil, pullDownMenu: titleMenu)
check(titled.pullsDown, "init(title:image:pullDownMenu:) makes a pull-down button")
check(titled.title == "T", "the title form sets the title")
check(titled.menu === titleMenu, "the menu is the caller's object")
check(titleMenu.numberOfItems == 2 && itemTitle(titleMenu, 0) == "first", "the title form does not rename the first item")
check(titled.titleOfSelectedItem == "first", "titleOfSelectedItem is still the first item's title")

let both = NSPopUpButton(title: "Both", image: image, pullDownMenu: makeMenu())
check(both.title == "Both", "title with an image")
let defaulted = NSPopUpButton(title: "Default", pullDownMenu: makeMenu())
check(defaulted.pullsDown && defaulted.title == "Default", "the image defaults to nil")

// An empty menu, observed on the Mac (probe symbols_b_probe2.txt lines 56-58): pullsDown, 0 items, titleOfSelectedItem
// nil, title "T" for the title form and "" for the image-only form; nothing is raised and nothing is added.
let emptyMenu = NSMenu(title: "Empty")
let onEmpty = NSPopUpButton(title: "T", image: nil, pullDownMenu: emptyMenu)
check(onEmpty.pullsDown && onEmpty.title == "T" && emptyMenu.numberOfItems == 0 && onEmpty.titleOfSelectedItem == nil,
      "title form on an empty menu: pull-down, title T, no items, no selected title")
let emptyImage = NSMenu(title: "EmptyImage")
let onEmptyImage = NSPopUpButton(image: image, pullDownMenu: emptyImage)
check(onEmptyImage.pullsDown && onEmptyImage.title == "" && emptyImage.numberOfItems == 0 && onEmptyImage.titleOfSelectedItem == nil,
      "image-only form on an empty menu: pull-down, empty title, no items, no selected title")

print(failures == 0 ? "ALL PASS" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
