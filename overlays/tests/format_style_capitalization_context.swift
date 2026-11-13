import Foundation

var failures = 0
func check(_ condition: Bool, _ name: String) {
    if !condition {
        print("FAIL: \(name)")
        failures += 1
    }
}

let contexts: [FormatStyleCapitalizationContext] = [.unknown, .standalone, .listItem, .beginningOfSentence, .middleOfSentence]
check(Set(contexts).count == contexts.count, "contexts are distinct")
check(FormatStyleCapitalizationContext.listItem == .listItem, "equal contexts compare equal")
for context in contexts {
    let decoded = try? JSONDecoder().decode(FormatStyleCapitalizationContext.self, from: JSONEncoder().encode(context))
    check(decoded == context, "Codable round trip \(context)")
}

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
