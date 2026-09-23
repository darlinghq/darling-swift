import Foundation

var failures = 0
func check(_ condition: Bool, _ name: String) {
    if !condition {
        print("FAIL: \(name)")
        failures += 1
    }
}

var template = Array("/tmp/darling-url-path.XXXXXX".utf8CString)
if let made = mkdtemp(&template) {
    let base = String(cString: made)
    let target = base + "/target"
    let link = base + "/link"
    check(mkdir(target, 0o700) == 0, "create target directory")
    check(symlink(target, link) == 0, "create symbolic link")

    let dotted = URL(fileURLWithPath: base + "/./target/../target", isDirectory: true)
    check(dotted.standardizedFileURL.path == target, "standardizedFileURL removes dot segments")
    let linked = URL(fileURLWithPath: link, isDirectory: true)
    let resolved = linked.resolvingSymlinksInPath().path
    if let canonical = realpath(target, nil) {
        let expected = String(cString: canonical)
        check(resolved == expected, "resolvingSymlinksInPath resolves link (got \(resolved), expected \(expected))")
        free(canonical)
    } else {
        check(false, "realpath target")
    }

    if let web = URL(string: "https://example.com/a/../b") {
        check(web.standardizedFileURL == web, "non-file standardizedFileURL unchanged")
        check(web.resolvingSymlinksInPath() == web, "non-file symlink resolution unchanged")
    } else {
        check(false, "create web URL")
    }

    unlink(link)
    rmdir(target)
    rmdir(base)
} else {
    check(false, "mkdtemp")
}

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
