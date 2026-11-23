// A Data made from an NSData must behave as a value under Darling: a write through withUnsafeMutableBytes, the
// subscript, replaceSubrange, append or resetBytes changes that Data only, never the NSData it wraps and never another
// Data made from the same NSData. Data(referencing:) documents that a mutated Data copies the contents first.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

func pattern(_ n: Int) -> Data { Data((0..<n).map { UInt8(truncatingIfNeeded: $0 &* 7 &+ 1) }) }
func contents(_ nsdata: NSData) -> [UInt8] {
    Array(UnsafeRawBufferPointer(start: nsdata.bytes, count: nsdata.length()))
}
func edited(_ bytes: [UInt8], _ index: Int, _ value: UInt8) -> [UInt8] {
    var copy = bytes
    copy[index] = value
    return copy
}
func write(_ d: inout Data, at i: Int, _ value: UInt8) {
    d.withUnsafeMutableBytes { (buffer: UnsafeMutableRawBufferPointer) in buffer[i] = value }
}

// Data(referencing:), then a write through withUnsafeMutableBytes: 1 and 14 bytes are inline, a copy by construction, so
// those two sizes are GUARDS (they cannot fail, and pass in every variant); 15 is a slice and 100_000 a large slice,
// the cases that fail without the fix.
for n in [1, 14, 15, 100_000] {
    let expected = Array(pattern(n))
    let nsdata = (NSData(bytes: expected, length: n) as NSData?)!
    var referencing = Data(referencing: nsdata)
    write(&referencing, at: n - 1, 0x99)
    check(Array(referencing) == edited(expected, n - 1, 0x99), "withUnsafeMutableBytes write is seen by the Data, \(n) bytes")
    check(contents(nsdata) == expected, "withUnsafeMutableBytes write leaves the NSData unchanged, \(n) bytes")
    check(Array(Data(referencing: nsdata)) == expected, "a Data made from the NSData afterwards sees the original bytes, \(n) bytes")
}

// Round trip: Data(referencing:) to NSData and back to Data. A write through any one of the Data values must not show
// in the first Data, the NSData in the middle or the original NSData. The hop goes through an NSArray in a function that
// is never inlined, so that the compiler cannot cancel the two bridge calls: the direct `(first as NSData) as Data` was
// not seen to alias in a Darling guest (it passed without the fix), and neither was this form: it also passed without
// the fix, so these round-trip cases do not discriminate the fix (round-trip aliasing is expected by reading the code,
// not reproduced in the guest).
@inline(never) func throughNSArray(_ nsdata: NSData) -> NSData {
    NSArray(object: nsdata)[0] as! NSData
}
for n in [15, 100_000] {
    let expected = Array(pattern(n))
    let nsdata = (NSData(bytes: expected, length: n) as NSData?)!
    let first = Data(referencing: nsdata)
    let back = throughNSArray(first as NSData)
    var third = back as Data
    write(&third, at: 0, 0x01)
    check(Array(third) == edited(expected, 0, 0x01), "round trip: the third Data shows its own write, \(n) bytes")
    check(Array(first) == expected && contents(back) == expected && contents(nsdata) == expected,
        "round trip: a withUnsafeMutableBytes write to the third Data changes neither earlier Data nor either NSData, \(n) bytes")
}

// A slice of Data(referencing:) whose parent is gone: the storage is unique and startIndex is not 0
for (total, range) in [(40, 5..<12), (100_000, 500..<600)] {
    let expected = Array(pattern(total))
    let nsdata = (NSData(bytes: expected, length: total) as NSData?)!
    var slice = Data(referencing: nsdata)[range]
    write(&slice, at: 2, 0x77)
    var edit = expected
    edit[range.lowerBound + 2] = 0x77
    check(contents(nsdata) == expected, "a withUnsafeMutableBytes write to a referencing slice leaves the NSData unchanged, \(total) bytes")
    check(slice.startIndex == range.lowerBound && Array(slice) == Array(edit[range]),
        "a referencing slice keeps its indices and shows its own write, \(total) bytes")
}

// The other writers already copy; these four cases are GUARDS that keep them honest: they pass in every variant
let expected = Array(pattern(100))
let nsdata = (NSData(bytes: expected, length: 100) as NSData?)!
var viaSubscript = Data(referencing: nsdata)
viaSubscript[3] = 0xEE
check(viaSubscript[3] == 0xEE && contents(nsdata) == expected, "subscript set leaves the NSData unchanged")
var viaReplace = Data(referencing: nsdata)
viaReplace.replaceSubrange(2..<4, with: [0xA1, 0xA2, 0xA3])
check(viaReplace.count == 101 && viaReplace[4] == 0xA3 && contents(nsdata) == expected, "replaceSubrange leaves the NSData unchanged")
var viaAppend = Data(referencing: nsdata)
viaAppend.append(0x55)
check(viaAppend.count == 101 && contents(nsdata) == expected, "append leaves the NSData unchanged")
var viaReset = Data(referencing: nsdata)
viaReset.resetBytes(in: 0..<4)
check(Array(viaReset[0..<4]) == [0, 0, 0, 0] && contents(nsdata) == expected, "resetBytes leaves the NSData unchanged")

// A Data of Int32.max bytes or more is held by a LargeSlice. The 2 GiB are copied by the write, so the case is skipped
// when there is no room for a second buffer.
let largeCount = Int(Int32.max)
if let probe = malloc(largeCount) {
    free(probe)
    if let memory = calloc(largeCount, 1) {
        let huge = (NSData(bytesNoCopy: memory, length: largeCount, freeWhenDone: false) as NSData?)!
        var referencing = Data(referencing: huge)
        write(&referencing, at: largeCount - 1, 0x7F)
        check(referencing[largeCount - 1] == 0x7F && referencing[0] == 0, "a Data of Int32.max bytes made from an NSData shows its own write")
        check(memory.load(fromByteOffset: largeCount - 1, as: UInt8.self) == 0 && huge.length() == largeCount,
            "a withUnsafeMutableBytes write to a Data of Int32.max bytes made from an NSData leaves the NSData unchanged")
        referencing = Data()
        free(memory)
    } else {
        print("skip: calloc of Int32.max bytes failed, the LargeSlice case was not run")
    }
} else {
    print("skip: no room for a second Int32.max-byte buffer, the LargeSlice case was not run")
}

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
