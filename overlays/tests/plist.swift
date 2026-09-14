// PropertyListEncoder and PropertyListDecoder through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}
func text(_ data: Data?) -> String {
    return data.flatMap { String(data: $0, encoding: .utf8) } ?? "<nil>"
}

struct Record : Codable, Equatable {
    var name: String
    var count: Int
    var ratio: Double
    var small: Float
    var enabled: Bool
    var tags: [String]
    var nickname: String?
    var created: Date
    var blob: Data
    var scores: [String : Int]
    var optionals: [Int?]
    var big: UInt64
    var minimum: Int64
    var nested: [[String : [Bool]]]
}

let record = Record(name: "Ada <&>", count: -42, ratio: 1.65, small: 1.1, enabled: true, tags: ["a", "b"], nickname: nil,
                    created: Date(timeIntervalSinceReferenceDate: 12345.5), blob: Data([0, 1, 254, 255]),
                    scores: ["x": 1, "y": 2], optionals: [1, nil, 3], big: UInt64.max, minimum: Int64.min,
                    nested: [["flags": [true, false]], [:]])

// Round trips in both formats.
let encoder = PropertyListEncoder()
check(encoder.outputFormat == NSPropertyListBinaryFormat_v1_0, "default output format is binary")
let binary = try? encoder.encode(record)
check(binary.map { $0.starts(with: Array("bplist00".utf8)) } ?? false, "binary output starts with bplist00")
let decoder = PropertyListDecoder()
check((try? decoder.decode(Record.self, from: binary ?? Data())) == record, "binary round trip")

encoder.outputFormat = NSPropertyListXMLFormat_v1_0
let xmlData = try? encoder.encode(record)
let xml = text(xmlData)
check(xml.hasPrefix("<?xml"), "XML output")
check(xml.contains("<key>name</key>") && xml.contains("<string>Ada &lt;&amp;&gt;</string>"), "XML keys and escaped strings")
check(xml.contains("<integer>18446744073709551615</integer>"), "UInt64.max written as an unsigned integer (\(xml.count) bytes)")
check(xml.contains("<integer>-9223372036854775808</integer>"), "Int64.min written")
check(xml.contains("<string>$null</string>"), "nil in an unkeyed container written as $null")
check(!xml.contains("nickname"), "absent optional key omitted")
check(xml.contains("<true/>") && xml.contains("<false/>"), "booleans written as <true/>/<false/>")
check(xml.contains("<data>") && xml.contains("<date>2001-01-01T03:25:45Z</date>"), "Data and Date written natively")
var format = NSPropertyListBinaryFormat_v1_0
let fromXML = try? decoder.decode(Record.self, from: xmlData ?? Data(), format: &format)
var wholeSeconds = record
wholeSeconds.created = Date(timeIntervalSinceReferenceDate: 12345) // XML dates have no fractional seconds
check(fromXML == wholeSeconds, "XML round trip")
if fromXML != wholeSeconds { print("  decoded:", String(describing: fromXML)) }
check(format == NSPropertyListXMLFormat_v1_0, "decode reports the XML format")

// Data written by hand, as another program would.
let handWritten = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>name</key><string>Grace</string><key>count</key><integer>7</integer><key>ratio</key><real>2.5</real>
<key>small</key><real>0.5</real><key>enabled</key><false/><key>tags</key><array/>
<key>created</key><date>2020-02-29T12:00:00Z</date><key>blob</key><data>AQID</data>
<key>scores</key><dict/><key>optionals</key><array><string>$null</string></array>
<key>big</key><integer>1</integer><key>minimum</key><integer>0</integer><key>nested</key><array/>
</dict></plist>
"""
let grace = try? decoder.decode(Record.self, from: Data(handWritten.utf8))
check(grace?.name == "Grace" && grace?.count == 7 && grace?.ratio == 2.5 && grace?.enabled == false, "decode handwritten XML")
check(grace?.created == Date(timeIntervalSince1970: 1582977600) && grace?.blob == Data([1, 2, 3]), "decode handwritten date and data")
check(grace?.optionals == [nil] && grace?.nickname == nil, "decode $null and a missing optional")

// Values of other Codable shapes.
class Base : Codable { var id = 1 }
final class Derived : Base {
    var extra = "e"
    enum CodingKeys : String, CodingKey { case extra }
    override init() { super.init() }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        extra = try container.decode(String.self, forKey: .extra)
        try super.init(from: container.superDecoder())
    }
    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(extra, forKey: .extra)
        try super.encode(to: container.superEncoder())
    }
}
let derived = Derived()
derived.id = 9
derived.extra = "x"
let derivedCopy = (try? encoder.encode(derived)).flatMap { try? decoder.decode(Derived.self, from: $0) }
check(derivedCopy?.id == 9 && derivedCopy?.extra == "x", "superEncoder and superDecoder")
check(text(try? encoder.encode(derived)).contains("<key>super</key>"), "super key")

struct UserInfoProbe : Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(encoder.userInfo[CodingUserInfoKey(rawValue: "k")!] as? String ?? "missing")
    }
}
encoder.userInfo[CodingUserInfoKey(rawValue: "k")!] = "v"
check(text(try? encoder.encode(UserInfoProbe())).contains("<string>v</string>"), "userInfo reaches the encoder")

// Errors.
func encodingError(_ body: () throws -> Void) -> String {
    do { try body(); return "none" } catch EncodingError.invalidValue(_, let context) { return "invalidValue: \(context.debugDescription)" } catch { return "other: \(error)" }
}
func decodingError(_ body: () throws -> Void) -> String {
    do { try body(); return "none" }
    catch DecodingError.typeMismatch { return "typeMismatch" }
    catch DecodingError.dataCorrupted { return "dataCorrupted" }
    catch DecodingError.keyNotFound { return "keyNotFound" }
    catch DecodingError.valueNotFound { return "valueNotFound" }
    catch { return "other: \(error)" }
}
check(encodingError { _ = try encoder.encode(5) }.hasPrefix("invalidValue: Top-level Int encoded as number"), "top-level number rejected")
check(encodingError { _ = try encoder.encode("s") }.hasPrefix("invalidValue: Top-level String encoded as string"), "top-level string rejected")
check(encodingError { _ = try encoder.encode(Date()) }.hasPrefix("invalidValue: Top-level Date encoded as date"), "top-level date rejected")
check(decodingError { _ = try decoder.decode([Int].self, from: Data("not a plist".utf8)) } == "dataCorrupted", "invalid data")
let numbers = (try? encoder.encode(["int": 300, "negative": -1])) ?? Data()
check(decodingError { _ = try decoder.decode([String : Int8].self, from: numbers) } == "dataCorrupted", "300 does not fit in Int8")
check(decodingError { _ = try decoder.decode([String : UInt].self, from: numbers) } == "dataCorrupted", "-1 does not fit in UInt")
check((try? decoder.decode([String : Int16].self, from: numbers)) == ["int": 300, "negative": -1], "Int16 values")
struct Widths : Codable, Equatable {
    var i8: Int8, u8: UInt8, i16: Int16, u16: UInt16, i32: Int32, u32: UInt32, u: UInt, i: Int
}
let widths = Widths(i8: .min, u8: .max, i16: .min, u16: .max, i32: .min, u32: .max, u: .max, i: .min)
check((try? decoder.decode(Widths.self, from: encoder.encode(widths))) == widths, "fixed-width integer limits round trip (XML)")
encoder.outputFormat = NSPropertyListBinaryFormat_v1_0
check((try? decoder.decode(Widths.self, from: encoder.encode(widths))) == widths, "fixed-width integer limits round trip (binary)")
encoder.outputFormat = NSPropertyListXMLFormat_v1_0
check(decodingError { _ = try decoder.decode([String : UInt8].self, from: numbers) } == "dataCorrupted", "300 does not fit in UInt8")
check(decodingError { _ = try decoder.decode([UInt32].self, from: encoder.encode([UInt64(UInt32.max) + 1])) } == "dataCorrupted", "2^32 does not fit in UInt32")
let fractions = (try? encoder.encode([1.5, 2.0])) ?? Data()
check(decodingError { _ = try decoder.decode([Int].self, from: fractions) } == "dataCorrupted", "1.5 does not fit in Int")
check((try? decoder.decode([Double].self, from: fractions)) == [1.5, 2.0], "Double values")
let bools = (try? encoder.encode([true])) ?? Data()
check(decodingError { _ = try decoder.decode([Int].self, from: bools) } == "typeMismatch", "Bool is not an Int")
check(decodingError { _ = try decoder.decode([Bool].self, from: (try? encoder.encode([1])) ?? Data()) } == "typeMismatch", "1 is not a Bool")
check(decodingError { _ = try decoder.decode([String : String].self, from: numbers) } == "typeMismatch", "number is not a String")
check(decodingError { _ = try decoder.decode(Record.self, from: numbers) } == "keyNotFound", "missing key")
check((try? decoder.decode([UInt64].self, from: encoder.encode([UInt64.max, 0]))) == [UInt64.max, 0], "UInt64.max round trip (XML)")
encoder.outputFormat = NSPropertyListBinaryFormat_v1_0
check((try? decoder.decode([UInt64].self, from: encoder.encode([UInt64.max, 1 << 63]))) == [UInt64.max, 1 << 63], "UInt64 above Int64.max round trip (binary)")
check(decodingError { _ = try decoder.decode([Int64].self, from: encoder.encode([UInt64.max])) } == "dataCorrupted", "UInt64.max does not fit in Int64")

print(failures == 0 ? "PASS" : "FAILURES: \(failures)")
