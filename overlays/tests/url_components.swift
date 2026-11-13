// URLComponents and URLQueryItem through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

// Parsing
let c = URLComponents(string: "https://user:p%40ss@example.com:8443/a%20b/c?q=swift%20darling&flag&empty=#top")!
check(c.scheme == "https", "scheme")
check(c.user == "user" && c.password == "p@ss", "user and decoded password")
check(c.percentEncodedPassword == "p%40ss", "percentEncodedPassword")
check(c.host == "example.com" && c.port == 8443, "host and port")
check(c.path == "/a b/c" && c.percentEncodedPath == "/a%20b/c", "path decoded and percent-encoded")
check(c.query == "q=swift darling&flag&empty=", "query (\(String(describing: c.query)))")
check(c.fragment == "top", "fragment")
let items = c.queryItems!
check(items == [URLQueryItem(name: "q", value: "swift darling"), URLQueryItem(name: "flag", value: nil), URLQueryItem(name: "empty", value: "")],
      "queryItems (\(items))")
check(c.string == "https://user:p%40ss@example.com:8443/a%20b/c?q=swift%20darling&flag&empty=#top", "string round-trips")
check(URLComponents(string: "https://exa mple.com") == nil, "invalid characters give nil")
check(URLComponents(string: "http://host:port/") == nil, "non-numeric port gives nil")
check(URLComponents(string: "http://[::1]:80/x")?.host == "[::1]", "IPv6 host")
check(URLComponents(string: "mailto:someone@example.com")?.path == "someone@example.com", "no authority")
check(URLComponents(string: "/relative/path?x=1")?.scheme == nil, "relative reference")

// Building
var b = URLComponents()
b.scheme = "https"
b.host = "api.example.com"
b.path = "/search results"
b.queryItems = [URLQueryItem(name: "q", value: "a&b=c"), URLQueryItem(name: "page", value: "2")]
check(b.percentEncodedQuery == "q=a%26b=c&page=2", "queryItems setter encodes & (\(String(describing: b.percentEncodedQuery)))")
check(b.string == "https://api.example.com/search%20results?q=a%26b=c&page=2", "built string (\(String(describing: b.string)))")
check(b.url?.absoluteString == b.string, "url")
check(b.queryItems?.first?.value == "a&b=c", "queryItems getter decodes")
b.queryItems = []
check(b.query == "" && b.queryItems == [], "empty query items give an empty query")
b.queryItems = nil
check(b.query == nil && b.string == "https://api.example.com/search%20results", "nil query items remove the query")
var noSlash = URLComponents()
noSlash.host = "example.com"
noSlash.path = "relative"
check(noSlash.string == nil, "authority with a path not starting with / gives nil")

// From URLs
let base = URL(string: "https://example.com/dir/")!
let relative = URL(string: "file.txt?x=1", relativeTo: base)!
check(URLComponents(url: relative, resolvingAgainstBaseURL: true)?.path == "/dir/file.txt", "resolvingAgainstBaseURL: true")
check(URLComponents(url: relative, resolvingAgainstBaseURL: false)?.path == "file.txt", "resolvingAgainstBaseURL: false")
check(URLComponents(url: base, resolvingAgainstBaseURL: false)?.host == "example.com", "absolute URL")

// Value semantics
var copy = c
copy.host = "other.example"
check(c.host == "example.com" && copy.host == "other.example", "value semantics")
check(Set([c, c, copy]).count == 2, "Hashable")
check(URLQueryItem(name: "k", value: "v").description == "k=v", "URLQueryItem description")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
