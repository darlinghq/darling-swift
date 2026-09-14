// URL through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

// Web URLs
let web = URL(string: "https://user:pw@example.com:8443/docs/guide.html?lang=en#intro")!
check(web.scheme == "https", "scheme")
check(web.host == "example.com", "host")
check(web.port == 8443, "port")
check(web.user == "user" && web.password == "pw", "user and password")
check(web.path == "/docs/guide.html", "path (\(web.path))")
check(web.query == "lang=en" && web.fragment == "intro", "query and fragment")
check(web.lastPathComponent == "guide.html" && web.pathExtension == "html", "lastPathComponent and pathExtension")
check(web.pathComponents == ["/", "docs", "guide.html"], "pathComponents (\(web.pathComponents))")
check(web.absoluteString == "https://user:pw@example.com:8443/docs/guide.html?lang=en#intro", "absoluteString")
check(!web.isFileURL, "web URL isn't a file URL")
check(URL(string: "") == nil, "empty string gives nil")

// Relative URLs
let base = URL(string: "https://example.com/a/b/")!
let relative = URL(string: "c/d.txt", relativeTo: base)!
check(relative.absoluteString == "https://example.com/a/b/c/d.txt", "relative URL resolves (\(relative.absoluteString))")
check(relative.relativeString == "c/d.txt", "relativeString")
check(relative.baseURL == base, "baseURL")

// File URLs and path manipulation
let file = URL(fileURLWithPath: "/tmp/darling/report.txt")
check(file.isFileURL && file.path == "/tmp/darling/report.txt", "file URL path (\(file.path))")
check(file.deletingPathExtension().lastPathComponent == "report", "deletingPathExtension")
check(file.deletingLastPathComponent().path == "/tmp/darling", "deletingLastPathComponent (\(file.deletingLastPathComponent().path))")
check(file.deletingPathExtension().appendingPathExtension("md").lastPathComponent == "report.md", "appendingPathExtension")
let dir = URL(fileURLWithPath: "/tmp/darling", isDirectory: true)
check(dir.appendingPathComponent("x.txt").path == "/tmp/darling/x.txt", "appendingPathComponent")
check(dir.appending(path: "sub", directoryHint: .isDirectory).absoluteString.hasSuffix("/tmp/darling/sub/"), "appending(path:directoryHint:)")
var mutable = dir
mutable.append(component: "y.txt")
check(mutable.lastPathComponent == "y.txt", "append(component:)")

// Bridging and equality
let ns = web as NSURL
check(ns.absoluteString() == web.absoluteString, "URL bridges to NSURL")
check((ns as URL) == web, "NSURL bridges back and compares equal")
check(Set([web, web, file]).count == 2, "URL is Hashable")
check(web.description == web.absoluteString, "description (\(web.description))")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
