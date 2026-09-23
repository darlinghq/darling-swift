// JSONEncoder and JSONDecoder through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}
func text(_ data: Data?) -> String {
    return data.flatMap { String(data: $0, encoding: .utf8) } ?? "<nil>"
}

struct Person : Codable, Equatable {
    var name: String
    var age: Int
    var height: Double
    var isAdmin: Bool
    var tags: [String]
    var nickname: String?
    var homepage: URL
    var avatar: Data
    var scores: [String : Int]
}

struct Floats : Codable {
    var float: Float
    var whole: Double
    var large: Double
    var negativeZero: Double
}

let person = Person(name: "Ada/L", age: 36, height: 1.65, isAdmin: true, tags: ["math", "code"], nickname: nil,
                    homepage: URL(string: "https://example.com/ada")!, avatar: Data([1, 2, 3]), scores: ["b": 2, "a": 1])

// Encoding
let encoder = JSONEncoder()
encoder.outputFormatting = .sortedKeys
let encoded = try? encoder.encode(person)
check(text(encoded) == #"{"age":36,"avatar":"AQID","height":1.65,"homepage":"https:\/\/example.com\/ada","isAdmin":true,"name":"Ada\/L","scores":{"a":1,"b":2},"tags":["math","code"]}"#,
      "encode with sorted keys (\(text(encoded)))")
encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
check(text(try? encoder.encode(["url": "a/b"])) == #"{"url":"a/b"}"#, "withoutEscapingSlashes")
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let pretty = text(try? encoder.encode(["b": [true, nil], "a": [Bool?]()] as [String : [Bool?]]))
check(pretty == "{\n  \"a\" : [\n\n  ],\n  \"b\" : [\n    true,\n    null\n  ]\n}", "prettyPrinted, including an empty array (\(pretty))")
encoder.outputFormatting = .sortedKeys
let mixedKeys = text(try? encoder.encode(["b": 1, "B": 2, "a10": 3, "a2": 4]))
check(mixedKeys == #"{"a2":4,"a10":3,"B":2,"b":1}"#, "sortedKeys compares numerically and case-insensitively (\(mixedKeys))")
let floats = text(try? encoder.encode(Floats(float: 1.1, whole: 3, large: 1e16, negativeZero: -0.0)))
check(floats == #"{"float":1.1,"large":1e+16,"negativeZero":-0,"whole":3}"#, "floating-point output (\(floats))")

// Decoding and round trips
let decoder = JSONDecoder()
if let encoded = encoded, let decoded = try? decoder.decode(Person.self, from: encoded) {
    check(decoded == person, "round trip")
} else {
    check(false, "round trip")
}
check((try? decoder.decode([String : Int?].self, from: Data(#"{"x": null, "y": 5}"#.utf8))) == ["x": nil, "y": 5], "decode nulls and whitespace")
check((try? decoder.decode(String.self, from: Data(#""é🦀\n""#.utf8))) == "é🦀\n", "unicode and escape sequences")
check(text(try? JSONEncoder().encode("\u{1}\t\"")) == #""\u0001\t\"""#, "control characters are escaped")
check(text(try? JSONEncoder().encode(42)) == "42" && (try? decoder.decode(Int.self, from: Data("42".utf8))) == 42, "top-level fragments")
check((try? decoder.decode([Double].self, from: Data("[1.5e3, -0.25, 7]".utf8))) == [1500, -0.25, 7], "floating-point numbers")
check(text(try? JSONEncoder().encode([UInt64.max])) == "[18446744073709551615]", "UInt64.max encodes exactly")
check((try? decoder.decode([UInt64].self, from: try JSONEncoder().encode([UInt64.max]))) == [UInt64.max], "UInt64.max round trip")
check((try? decoder.decode([Double].self, from: Data("[18446744073709551615]".utf8))) == [18446744073709551615.0], "a huge integer decodes as Double")
if case .dataCorrupted? = decodingError([Int].self, "[18446744073709551615]") { check(true, "a huge integer doesn't fit in Int") } else { check(false, "a huge integer doesn't fit in Int") }
check((try? decoder.decode(String.self, from: Data(#""\u00e9\ud83e\udd80""#.utf8))) == "\u{E9}\u{1F980}", "\\u escapes and surrogate pairs")
check((try? decoder.decode([Int].self, from: Data([0xEF, 0xBB, 0xBF] + Array("[1]".utf8)))) == [1], "UTF-8 byte-order mark")
check((try? decoder.decode(Double.self, from: Data("-0".utf8)))?.sign == .minus, "-0 keeps its sign as a Double")
check((try? decoder.decode([Int64].self, from: try JSONEncoder().encode([Int64.min]))) == [Int64.min], "Int64.min round trip")
check((try? decoder.decode([Bool].self, from: Data("[true,false]".utf8))) == [true, false], "booleans")

// Errors
func decodingError<T : Decodable>(_ type: T.Type, _ json: String) -> DecodingError? {
    do {
        _ = try decoder.decode(type, from: Data(json.utf8))
        return nil
    } catch {
        return error as? DecodingError
    }
}
if case .typeMismatch? = decodingError(Int.self, #""x""#) { check(true, "type mismatch") } else { check(false, "type mismatch") }
if case .typeMismatch? = decodingError(Int.self, "true") { check(true, "a boolean is not an integer") } else { check(false, "a boolean is not an integer") }
if case .dataCorrupted? = decodingError(Int8.self, "300") { check(true, "overflow") } else { check(false, "overflow") }
if case .dataCorrupted? = decodingError(Int.self, "1.5") { check(true, "fraction into an integer") } else { check(false, "fraction into an integer") }
if case .dataCorrupted? = decodingError([Int].self, "[1,") { check(true, "invalid JSON") } else { check(false, "invalid JSON") }
if case .keyNotFound? = decodingError(Person.self, "{}") { check(true, "missing key") } else { check(false, "missing key") }
for (json, label) in [(#""\ud83e""#, "lone surrogate"), ("[1] x", "trailing garbage"), ("[01]", "leading zero")] {
    if case .dataCorrupted? = decodingError([String].self, json) ?? decodingError(String.self, json) { check(true, label) } else { check(false, label) }
}
do {
    _ = try decoder.decode(String.self, from: Data([0x22, 0xFF, 0x22]))
    check(false, "invalid UTF-8")
} catch DecodingError.dataCorrupted(let context) {
    let underlying = context.underlyingError as NSError?
    check(underlying?.domain() == "NSCocoaErrorDomain" && underlying?.code() == 3840, "invalid UTF-8 reports NSCocoaErrorDomain 3840")
} catch {
    check(false, "invalid UTF-8 (\(error))")
}
do {
    _ = try JSONEncoder().encode([Double.nan])
    check(false, "NaN throws")
} catch {
    check(error is EncodingError, "NaN throws")
}
let lenient = JSONEncoder()
lenient.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "+inf", negativeInfinity: "-inf", nan: "nan")
check(text(try? lenient.encode([Double.infinity])) == #"["+inf"]"#, "convertToString")

// Strategies
struct Account : Codable, Equatable {
    var firstName: String
    var createdAt: Date
}
let summer = Date(timeIntervalSince1970: 1626350400)
let snake = JSONEncoder()
snake.keyEncodingStrategy = .convertToSnakeCase
snake.dateEncodingStrategy = .iso8601
snake.outputFormatting = .sortedKeys
let snakeData = try? snake.encode(Account(firstName: "Ada", createdAt: summer))
check(text(snakeData) == #"{"created_at":"2021-07-15T12:00:00Z","first_name":"Ada"}"#, "snake case and ISO 8601 (\(text(snakeData)))")
let camel = JSONDecoder()
camel.keyDecodingStrategy = .convertFromSnakeCase
camel.dateDecodingStrategy = .iso8601
check(snakeData.flatMap { try? camel.decode(Account.self, from: $0) } == Account(firstName: "Ada", createdAt: summer), "decode snake case and ISO 8601")
check((try? camel.decode([String : Date].self, from: Data(#"{"d":"2021-07-15T14:30:00+02:30"}"#.utf8)))?["d"] == summer, "ISO 8601 with an offset")
if case .dataCorrupted? = { () -> DecodingError? in
    do { _ = try camel.decode([Date].self, from: Data(#"["2021-02-30T00:00:00Z"]"#.utf8)); return nil } catch { return error as? DecodingError }
}() { check(true, "invalid ISO 8601 date") } else { check(false, "invalid ISO 8601 date") }
let seconds = JSONEncoder()
seconds.dateEncodingStrategy = .millisecondsSince1970
check(text(try? seconds.encode([summer])) == "[1626350400000]", "millisecondsSince1970")
let custom = JSONDecoder()
custom.dateDecodingStrategy = .custom { decoder in
    Date(timeIntervalSince1970: try Double(decoder.singleValueContainer().decode(String.self))!)
}
check((try? custom.decode([Date].self, from: Data(#"["1626350400"]"#.utf8))) == [summer], "custom date strategy")
let dayFormatter = DateFormatter()
dayFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
dayFormatter.timeZone = NSTimeZone(name: "UTC")
dayFormatter.dateFormat = "yyyy-MM-dd HH:mm"
let formattedEncoder = JSONEncoder()
formattedEncoder.dateEncodingStrategy = .formatted(dayFormatter)
check(text(try? formattedEncoder.encode([summer])) == #"["2021-07-15 12:00"]"#, "formatted date encoding")
let formattedDecoder = JSONDecoder()
formattedDecoder.dateDecodingStrategy = .formatted(dayFormatter)
check((try? formattedDecoder.decode([Date].self, from: Data(#"["2021-07-15 12:00"]"#.utf8))) == [summer], "formatted date decoding")
check(text(try? snake.encode(["someKey": 1] as [String : Int])) == #"{"someKey":1}"#, "string-keyed dictionaries keep their keys")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
