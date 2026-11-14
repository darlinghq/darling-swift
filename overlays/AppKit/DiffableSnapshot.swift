// NSDiffableDataSourceSnapshot: an ordered list of unique section identifiers, each holding an ordered list of item
// identifiers that are unique across the whole snapshot.
//
// Provenance. Names: Reminders, Mail and App Store import the type, the initializer, the sectionIdentifiers,
// itemIdentifiers and numberOfItems/numberOfSections getters, appendSections, appendItems, reloadItems and
// moveItem(_:beforeItem:)/(_:afterItem:) (rung 5, llvm-nm -u -m). Declarations and generic constraints: Apple's public
// documentation (https://developer.apple.com/documentation/appkit/nsdiffabledatasourcesnapshot-swift.struct and its
// member pages): `<SectionIdentifierType: Hashable, ItemIdentifierType: Hashable>`, `appendItems(_:toSection:)` with a
// nil default, `numberOfItems(inSection:)` taking a section identifier and failing on an unknown one.
// The struct is not frozen under library evolution, so apps reach it through exported accessors and its stored layout
// is free. Every documented member is implemented, not only the demanded ones, so the type is complete.
// Cost: appends and the counts are O(1) per identifier; indexOfItem, sectionIdentifier(containingItem:) and the missing-identifier
// checks scan the items linearly.
// GUESS (the documentation gives signatures, not behaviour): that an identifier already present, an anchor or section
// that is absent, or an absent identifier to delete, move or reload traps (the documented behaviour for a missing
// section in numberOfItems(inSection:)), and that deleting the last item of a section keeps the section.

@_exported import Foundation

/// A snapshot of the sections and items a diffable data source shows.
public struct NSDiffableDataSourceSnapshot<SectionIdentifierType: Hashable, ItemIdentifierType: Hashable> {
    private var sections: [SectionIdentifierType] = []
    private var itemsBySection: [[ItemIdentifierType]] = []
    // Every item identifier, so the uniqueness check of an append does not rebuild a set from all items.
    private var allItems: Set<ItemIdentifierType> = []

    public init() {}

    // MARK: Metrics

    public var numberOfItems: Int { return allItems.count }

    public var numberOfSections: Int { return sections.count }

    public func numberOfItems(inSection identifier: SectionIdentifierType) -> Int {
        return itemsBySection[requireSection(identifier)].count
    }

    // MARK: Identifiers

    public var sectionIdentifiers: [SectionIdentifierType] { return sections }

    public var itemIdentifiers: [ItemIdentifierType] { return itemsBySection.flatMap { $0 } }

    public func itemIdentifiers(inSection identifier: SectionIdentifierType) -> [ItemIdentifierType] {
        return itemsBySection[requireSection(identifier)]
    }

    public func sectionIdentifier(containingItem identifier: ItemIdentifierType) -> SectionIdentifierType? {
        return locate(identifier).map { sections[$0.section] }
    }

    public func indexOfItem(_ identifier: ItemIdentifierType) -> Int? {
        guard let place = locate(identifier) else { return nil }
        return itemsBySection[..<place.section].reduce(place.item) { $0 + $1.count }
    }

    public func indexOfSection(_ identifier: SectionIdentifierType) -> Int? {
        return sections.firstIndex(of: identifier)
    }

    // MARK: Adding

    public mutating func appendSections(_ identifiers: [SectionIdentifierType]) {
        requireNewSections(identifiers)
        sections.append(contentsOf: identifiers)
        itemsBySection.append(contentsOf: identifiers.map { _ in [] })
    }

    /// Appends to `sectionIdentifier`, or to the last section when it is `nil`.
    public mutating func appendItems(_ identifiers: [ItemIdentifierType], toSection sectionIdentifier: SectionIdentifierType? = nil) {
        let index: Int
        if let sectionIdentifier = sectionIdentifier {
            index = requireSection(sectionIdentifier)
        } else {
            guard let last = sections.indices.last else {
                preconditionFailure("Cannot append items to a snapshot with no sections")
            }
            index = last
        }
        requireNewItems(identifiers)
        itemsBySection[index].append(contentsOf: identifiers)
        allItems.formUnion(identifiers)
    }

    public mutating func insertSections(_ identifiers: [SectionIdentifierType], beforeSection toIdentifier: SectionIdentifierType) {
        insertSections(identifiers, at: requireSection(toIdentifier))
    }

    public mutating func insertSections(_ identifiers: [SectionIdentifierType], afterSection toIdentifier: SectionIdentifierType) {
        insertSections(identifiers, at: requireSection(toIdentifier) + 1)
    }

    public mutating func insertItems(_ identifiers: [ItemIdentifierType], beforeItem beforeIdentifier: ItemIdentifierType) {
        let place = requireItem(beforeIdentifier)
        requireNewItems(identifiers)
        itemsBySection[place.section].insert(contentsOf: identifiers, at: place.item)
        allItems.formUnion(identifiers)
    }

    public mutating func insertItems(_ identifiers: [ItemIdentifierType], afterItem afterIdentifier: ItemIdentifierType) {
        let place = requireItem(afterIdentifier)
        requireNewItems(identifiers)
        itemsBySection[place.section].insert(contentsOf: identifiers, at: place.item + 1)
        allItems.formUnion(identifiers)
    }

    // MARK: Removing

    public mutating func deleteAllItems() {
        sections.removeAll()
        itemsBySection.removeAll()
        allItems.removeAll()
    }

    public mutating func deleteItems(_ identifiers: [ItemIdentifierType]) {
        for identifier in identifiers {
            let place = requireItem(identifier)
            itemsBySection[place.section].remove(at: place.item)
            allItems.remove(identifier)
        }
    }

    public mutating func deleteSections(_ identifiers: [SectionIdentifierType]) {
        for identifier in identifiers {
            let index = requireSection(identifier)
            sections.remove(at: index)
            allItems.subtract(itemsBySection.remove(at: index))
        }
    }

    // MARK: Moving

    public mutating func moveItem(_ identifier: ItemIdentifierType, beforeItem toIdentifier: ItemIdentifierType) {
        precondition(identifier != toIdentifier, "Cannot move item \(identifier) relative to itself")
        deleteItems([identifier])
        insertItems([identifier], beforeItem: toIdentifier)
    }

    public mutating func moveItem(_ identifier: ItemIdentifierType, afterItem toIdentifier: ItemIdentifierType) {
        precondition(identifier != toIdentifier, "Cannot move item \(identifier) relative to itself")
        deleteItems([identifier])
        insertItems([identifier], afterItem: toIdentifier)
    }

    public mutating func moveSection(_ identifier: SectionIdentifierType, beforeSection toIdentifier: SectionIdentifierType) {
        moveSection(identifier, relativeTo: toIdentifier, offset: 0)
    }

    public mutating func moveSection(_ identifier: SectionIdentifierType, afterSection toIdentifier: SectionIdentifierType) {
        moveSection(identifier, relativeTo: toIdentifier, offset: 1)
    }

    // MARK: Reloading

    // The data sources reload everything on apply, so there is nothing to record; the identifiers are still checked.
    public mutating func reloadItems(_ identifiers: [ItemIdentifierType]) {
        for identifier in identifiers { _ = requireItem(identifier) }
    }

    public mutating func reloadSections(_ identifiers: [SectionIdentifierType]) {
        for identifier in identifiers { _ = requireSection(identifier) }
    }

    // MARK: Read by the data sources

    func numberOfItems(atSectionIndex index: Int) -> Int { return itemsBySection[index].count }

    func itemIdentifier(atRow row: Int) -> ItemIdentifierType? {
        guard row >= 0 else { return nil }
        var remaining = row
        for items in itemsBySection {
            if remaining < items.count { return items[remaining] }
            remaining -= items.count
        }
        return nil
    }

    func itemIdentifier(atSectionIndex section: Int, item: Int) -> ItemIdentifierType? {
        guard itemsBySection.indices.contains(section), itemsBySection[section].indices.contains(item) else { return nil }
        return itemsBySection[section][item]
    }

    // MARK: Helpers

    private func locate(_ identifier: ItemIdentifierType) -> (section: Int, item: Int)? {
        for section in itemsBySection.indices {
            if let item = itemsBySection[section].firstIndex(of: identifier) { return (section, item) }
        }
        return nil
    }

    private func requireItem(_ identifier: ItemIdentifierType) -> (section: Int, item: Int) {
        guard let place = locate(identifier) else {
            preconditionFailure("Item identifier \(identifier) is not in the snapshot")
        }
        return place
    }

    private func requireSection(_ identifier: SectionIdentifierType) -> Int {
        guard let index = sections.firstIndex(of: identifier) else {
            preconditionFailure("Section identifier \(identifier) is not in the snapshot")
        }
        return index
    }

    private func requireNewSections(_ identifiers: [SectionIdentifierType]) {
        var seen = Set(sections)
        for identifier in identifiers {
            precondition(seen.insert(identifier).inserted, "Section identifier \(identifier) is already in the snapshot")
        }
    }

    private func requireNewItems(_ identifiers: [ItemIdentifierType]) {
        var added = Set<ItemIdentifierType>()
        for identifier in identifiers {
            precondition(!allItems.contains(identifier) && added.insert(identifier).inserted,
                         "Item identifier \(identifier) is already in the snapshot")
        }
    }

    private mutating func insertSections(_ identifiers: [SectionIdentifierType], at index: Int) {
        requireNewSections(identifiers)
        sections.insert(contentsOf: identifiers, at: index)
        itemsBySection.insert(contentsOf: identifiers.map { _ in [] }, at: index)
    }

    private mutating func moveSection(_ identifier: SectionIdentifierType, relativeTo anchor: SectionIdentifierType, offset: Int) {
        precondition(identifier != anchor, "Cannot move section \(identifier) relative to itself")
        let from = requireSection(identifier)
        _ = requireSection(anchor)
        let items = itemsBySection.remove(at: from)
        sections.remove(at: from)
        let to = requireSection(anchor) + offset
        sections.insert(identifier, at: to)
        itemsBySection.insert(items, at: to)
    }
}
