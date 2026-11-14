// NSDiffableDataSourceSnapshot semantics. The snapshot is plain Swift, so besides running under Darling (against the
// AppKit overlay) the file runs on any host by compiling it together with AppKit/DiffableSnapshot.swift.
// Run as `<binary> --trap <case>` it performs one operation that must trap and exits 0 only if it did not; the parent
// run (no arguments) re-launches itself for each case and expects the child to die from a signal.
#if canImport(AppKit)
import AppKit
#endif
import Foundation
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

typealias Snapshot = NSDiffableDataSourceSnapshot<String, Int>

func sample() -> Snapshot {
    var s = Snapshot()
    s.appendSections(["a", "b", "c"])
    s.appendItems([1, 2, 3], toSection: "a")
    s.appendItems([4, 5], toSection: "b")
    return s
}

let trapCases: [String: () -> Void] = [
    "duplicate-item": { var s = sample(); s.appendItems([1], toSection: "b") },
    "duplicate-within-one-call": { var s = sample(); s.appendItems([7, 7], toSection: "a") },
    "duplicate-section": { var s = sample(); s.appendSections(["a"]) },
    "append-to-missing-section": { var s = sample(); s.appendItems([9], toSection: "z") },
    "append-with-no-sections": { var s = Snapshot(); s.appendItems([9]) },
    "count-in-missing-section": { _ = sample().numberOfItems(inSection: "z") },
    "insert-after-missing-item": { var s = sample(); s.insertItems([9], afterItem: 99) },
    "delete-missing-item": { var s = sample(); s.deleteItems([99]) },
    "move-onto-itself": { var s = sample(); s.moveItem(1, afterItem: 1) },
    "reload-missing-item": { var s = sample(); s.reloadItems([99]) },
]

if CommandLine.arguments.count == 3 && CommandLine.arguments[1] == "--trap" {
    guard let operation = trapCases[CommandLine.arguments[2]] else { exit(2) }
    operation()
    exit(0)
}

var s = sample()
check(s.numberOfSections == 3 && s.numberOfItems == 5, "counts")
check(s.sectionIdentifiers == ["a", "b", "c"] && s.itemIdentifiers == [1, 2, 3, 4, 5], "identifiers in order")
check(s.numberOfItems(inSection: "a") == 3 && s.numberOfItems(inSection: "c") == 0, "items in a section, empty section is 0")
check(s.itemIdentifiers(inSection: "b") == [4, 5], "item identifiers in a section")
check(s.sectionIdentifier(containingItem: 5) == "b" && s.sectionIdentifier(containingItem: 99) == nil, "section of an item")
check(s.indexOfItem(4) == 3 && s.indexOfItem(99) == nil, "index of an item counts across sections")
check(s.indexOfSection("c") == 2 && s.indexOfSection("z") == nil, "index of a section")

s.appendItems([6])
check(s.itemIdentifiers(inSection: "c") == [6], "appendItems without a section goes to the last one")

s.insertItems([10, 11], afterItem: 2)
check(s.itemIdentifiers(inSection: "a") == [1, 2, 10, 11, 3], "insert after")
s.insertItems([12], beforeItem: 1)
check(s.itemIdentifiers(inSection: "a") == [12, 1, 2, 10, 11, 3], "insert before")
s.deleteItems([10, 11, 12])
check(s.itemIdentifiers(inSection: "a") == [1, 2, 3], "delete items")

s.moveItem(1, afterItem: 4)
check(s.itemIdentifiers(inSection: "a") == [2, 3] && s.itemIdentifiers(inSection: "b") == [4, 1, 5], "move item after, across sections")
s.moveItem(5, beforeItem: 2)
check(s.itemIdentifiers(inSection: "a") == [5, 2, 3] && s.itemIdentifiers(inSection: "b") == [4, 1], "move item before, across sections")

s.insertSections(["x"], beforeSection: "b")
s.insertSections(["y"], afterSection: "b")
check(s.sectionIdentifiers == ["a", "x", "b", "y", "c"], "insert sections")
s.moveSection("c", beforeSection: "a")
check(s.sectionIdentifiers == ["c", "a", "x", "b", "y"], "move section before")
s.moveSection("c", afterSection: "x")
check(s.sectionIdentifiers == ["a", "x", "c", "b", "y"], "move section after")
check(s.itemIdentifiers(inSection: "c") == [6], "a moved section keeps its items")
s.deleteSections(["x", "y"])
check(s.sectionIdentifiers == ["a", "c", "b"], "delete sections")
s.reloadItems([6]); s.reloadSections(["a"])
check(s.numberOfItems == 6, "reloading changes nothing")

var withItems = sample()
withItems.deleteSections(["a"])
check(withItems.sectionIdentifiers == ["b", "c"] && withItems.numberOfItems == 2 && withItems.itemIdentifiers == [4, 5],
      "deleting a section removes its items")
withItems.appendItems([1], toSection: "c")
check(withItems.itemIdentifiers == [4, 5, 1], "an identifier of a deleted section can be reused")
withItems.deleteItems([4, 5])
check(withItems.sectionIdentifiers == ["b", "c"] && withItems.numberOfItems == 1, "deleting the last item keeps its section")

var many = Snapshot()
many.appendSections(["only"])
for i in 0..<20_000 { many.appendItems([i]) }
check(many.numberOfItems == 20_000 && many.itemIdentifiers.last == 19_999, "single appends scale")

var copy = s
copy.deleteAllItems()
check(copy.numberOfSections == 0 && copy.numberOfItems == 0 && s.numberOfItems == 6, "deleteAllItems empties a copy, not the original")

// Each trap case runs in a child process; the child must die from a signal.
func runChild(_ name: String) -> Int32 {
    var pid: pid_t = 0
    let arguments = [CommandLine.arguments[0], "--trap", name]
    var argv: [UnsafeMutablePointer<CChar>?] = arguments.map { strdup($0) } + [nil]
    defer { argv.forEach { free($0) } }
#if canImport(Darwin)
    var actions: posix_spawn_file_actions_t? = nil
#else
    var actions = posix_spawn_file_actions_t()
#endif
    posix_spawn_file_actions_init(&actions)
    posix_spawn_file_actions_addopen(&actions, 2, "/dev/null", O_WRONLY, 0)
    var environment: [UnsafeMutablePointer<CChar>?] = [nil]
    guard posix_spawn(&pid, CommandLine.arguments[0], &actions, nil, argv, environment) == 0 else { return -1 }
    var status: Int32 = 0
    waitpid(pid, &status, 0)
    return status
}

if !CommandLine.arguments.contains("--no-trap-children") {
    for name in trapCases.keys.sorted() {
        let status = runChild(name)
        let signal = status & 0x7f
        check(status != -1 && signal != 0 && signal != 0x7f, "\(name) traps")
    }
}

if failures != 0 { exit(1) }
