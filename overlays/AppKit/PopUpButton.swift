// NSPopUpButton.init(image:pullDownMenu:) and init(title:image:pullDownMenu:).
//
// Provenance. Declarations: Apple's public documentation (developer.apple.com/documentation/appkit/nspopupbutton/
// init(title:image:pulldownmenu:) and .../init(image:pulldownmenu:)): each "creates a standard pull-down button with a
// title, optional image, and menu"; compared with the macOS 26 SDK's Swift module interface (declarations only).
// Behaviour (black-box probe on macOS 26.7.3): both forms give pullsDown true and leave the menu as it was (same
// object, same two items, the first still titled "first"); the image-only form has title "" and keeps the image
// (`image === img`) and titleOfSelectedItem "first"; the title form with image nil has title "T". With an EMPTY menu
// both forms give pullsDown true, leave the menu with 0 items, and titleOfSelectedItem nil; the title is "" for the
// image-only form and "T" for the title form. Nothing is added to the menu and nothing is raised.
//
// Known gaps in Darling's AppKit, not in this file: NSPopUpButtonCell has no `usesItemFromMenu` and its -setImage:
// has no effect (it takes a pull-down button's image from the menu's first item), so the image is stored but not
// displayed, and `usesItemFromMenu` is not set.
//
// The title is set on the button's cell, through key-value coding, because Darling's NSPopUpButton -setTitle: on a
// pull-down button renames the menu's first item (and raises on an empty menu), which the Mac does not do.
//
// Known limitation: the title does not last. Darling's NSPopUpButtonCell has no `usesItemFromMenu`, so after
// -synchronizeTitleAndSelectedItem or a selection change (selectItem(at:)) the button shows the first item's title
// again, where the Mac keeps the title it was given because usesItemFromMenu is false. The real fix is
// `usesItemFromMenu` in Cocotron's NSPopUpButtonCell (a follow-up); this file cannot do it.

@_exported import Foundation

extension NSPopUpButton {
    /// A pull-down button that shows `image` and pulls down `menu`; its title is empty.
    public convenience init(image: NSImage, pullDownMenu: NSMenu) {
        self.init(frame: .zero, pullsDown: true)
        menu = pullDownMenu
        setCellTitle("")
        self.image = image
    }

    /// A pull-down button that shows `title` and `image` and pulls down `menu`.
    public convenience init(title: String, image: NSImage? = nil, pullDownMenu: NSMenu) {
        self.init(frame: .zero, pullsDown: true)
        menu = pullDownMenu
        setCellTitle(title)
        self.image = image
    }

    private func setCellTitle(_ title: String) {
        // An NSPopUpButton always has a cell; a missing one means the key-value route no longer works, so stop
        // instead of leaving the title silently unset.
        guard let cell = value(forKey: "cell") as? NSObject else {
            fatalError("NSPopUpButton has no cell: cannot set the pull-down button's title")
        }
        cell.setValue(title, forKey: "title")
    }
}
