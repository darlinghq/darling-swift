// URLResourceValues.contentType (UniformTypeIdentifiers overlay) over NSURLContentTypeKey, next to the typed
// Foundation resource keys. Exits non-zero on failure.

import Foundation
import UniformTypeIdentifiers

var failures = 0
func check(_ ok: Bool, _ what: String) {
	print("\(ok ? "PASS" : "FAIL"): \(what)")
	if !ok { failures += 1 }
}

let base = NSTemporaryDirectory() + "darling-url-content-type-\(getpid())"
check(mkdir(base, 0o700) == 0, "create base directory")
for name in ["notes.txt", "picture.png", "blob.qqqzzz"] {
	let fd = open(base + "/" + name, O_CREAT | O_EXCL | O_WRONLY, 0o600)
	check(fd >= 0, "create \(name)")
	if fd >= 0 { close(fd) }
}
check(mkdir(base + "/folder", 0o700) == 0, "create folder")
check(mkdir(base + "/Thing.app", 0o700) == 0, "create Thing.app")

func contentType(_ name: String) -> UTType? {
	try? URL(fileURLWithPath: base + "/" + name).resourceValues(forKeys: [.contentTypeKey]).contentType
}

check(contentType("notes.txt") == .plainText, "txt file is public.plain-text")
check(contentType("picture.png") == .png, "png file is public.png")
let unknown = contentType("blob.qqqzzz")
check(unknown?.isDynamic == true && unknown?.conforms(to: .data) == true && unknown?.preferredFilenameExtension == "qqqzzz",
	"unknown extension is a dynamic type conforming to data")
check(contentType("folder") == .folder, "directory is public.folder")
check(contentType("Thing.app") == .applicationBundle, ".app directory is an application bundle")

do {
	let values = try URL(fileURLWithPath: base + "/notes.txt").resourceValues(forKeys: [.contentTypeKey, .isDirectoryKey, .isRegularFileKey, .fileSizeKey])
	check(values.contentType == .plainText, "contentType alongside other keys")
	check(values.isDirectory == false && values.isRegularFile == true && values.fileSize == 0, "existing keys still work")
	check(values.allValues[.contentTypeKey] is UTType.ReferenceType, "allValues holds the Objective-C type")
	check(values.allValues.count == 4, "allValues has one entry per requested key")
	let other = try URL(fileURLWithPath: base + "/notes.txt").resourceValues(forKeys: [.isDirectoryKey])
	check(other.contentType == nil, "contentType is nil when not requested")
} catch {
	check(false, "resourceValues threw \(error)")
}
do {
	_ = try URL(fileURLWithPath: base + "/missing").resourceValues(forKeys: [.contentTypeKey])
	check(false, "missing file throws")
} catch {
	check(true, "missing file throws")
}

for name in ["notes.txt", "picture.png", "blob.qqqzzz"] { unlink(base + "/" + name) }
rmdir(base + "/folder")
rmdir(base + "/Thing.app")
rmdir(base)
print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
