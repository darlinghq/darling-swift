// URLRequest value semantics, Objective-C bridging, and URLError under Darling.
import Foundation

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { fatalError(message) }
}

let url = URL(string: "https://example.com/path")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("text/plain", forHTTPHeaderField: "Content-Type")

let original = request
request.httpMethod = "PATCH"
check(original.httpMethod == "POST", "copy-on-write kept the original method")
check(request.httpMethod == "PATCH", "the mutated copy has its own method")
check(original.value(forHTTPHeaderField: "Content-Type") == "text/plain", "copy retained the header")

let bridged = request._bridgeToObjectiveC()
let roundTrip = URLRequest._unconditionallyBridgeFromObjectiveC(bridged)
check(roundTrip.httpMethod == "PATCH", "Objective-C round trip retained the method")
check(roundTrip.url == url, "Objective-C round trip retained the URL")

let error = URLError(.unknown)
check(error.errorCode == -1, "unknown URL error has the expected code")
check(URLError.errorDomain == NSURLErrorDomain, "URL error uses the Foundation domain")
