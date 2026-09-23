import Foundation

var failures = 0
func check(_ condition: Bool, _ name: String) {
    if !condition {
        print("FAIL: \(name)")
        failures += 1
    }
}

let base = "/tmp/darling-url-resource-values-\(getpid())"
let file = base + ".file"
let directory = base + ".dir"
let link = base + ".link"
let fd = open(file, O_CREAT | O_EXCL | O_WRONLY, 0o600)
check(fd >= 0, "create file")
if fd >= 0 { close(fd) }
check(mkdir(directory, 0o700) == 0, "create directory")
check(symlink(file, link) == 0, "create symlink")

let regular = URLResourceKey(rawValue: NSURLIsRegularFileKey)
let isDirectory = URLResourceKey(rawValue: NSURLIsDirectoryKey)
let symbolic = URLResourceKey(rawValue: NSURLIsSymbolicLinkKey)
let size = URLResourceKey(rawValue: NSURLFileSizeKey)

do {
    let values = try URL(fileURLWithPath: file).resourceValues(forKeys: [regular, isDirectory, size])
    check(values.isRegularFile == true, "file is regular")
    check(values.isDirectory == false, "file is not directory")
    check(values.fileSize == 0, "empty file has zero size")
    check(values.isSymbolicLink == nil, "unrequested value is nil")
    let dirValues = try URL(fileURLWithPath: directory).resourceValues(forKeys: [regular, isDirectory])
    check(dirValues.isRegularFile == false, "directory is not regular")
    check(dirValues.isDirectory == true, "directory is directory")
    let linkValues = try URL(fileURLWithPath: link).resourceValues(forKeys: [symbolic])
    check(linkValues.isSymbolicLink == true, "link is symbolic")
} catch {
    check(false, "resource lookup threw \(error)")
}

unlink(link)
unlink(file)
rmdir(directory)
print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
