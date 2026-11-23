// Data.bytes, .span, .mutableBytes and .mutableSpan through the Foundation overlay, under Darling.
// Expectations come from Apple's documentation of the four properties (their types and mutability) and from the
// value semantics of Data: a span shows exactly the bytes of the Data, a write through a mutable span changes only
// that Data.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

func viaBytes(_ d: Data) -> [UInt8] {
    let raw = d.bytes
    return raw.withUnsafeBytes { Array($0) }
}
func viaSpan(_ d: Data) -> [UInt8] {
    let s = d.span
    return s.withUnsafeBufferPointer { Array($0) }
}
func writeViaMutableSpan(_ d: inout Data, at i: Int, _ value: UInt8) {
    var m = d.mutableSpan
    m[i] = value
}
func writeViaMutableBytes(_ d: inout Data, at i: Int, _ value: UInt8) {
    var m = d.mutableBytes
    m.storeBytes(of: value, toByteOffset: i, as: UInt8.self)
}
func pattern(_ n: Int) -> Data { Data((0..<n).map { UInt8(truncatingIfNeeded: $0 &* 7 &+ 1) }) }

// Empty
var empty = Data()
check(empty.bytes.byteCount == 0 && empty.span.count == 0, "an empty Data gives empty read-only spans")
check(empty.mutableBytes.byteCount == 0 && empty.mutableSpan.count == 0, "an empty Data gives empty mutable spans")
var emptySlice = pattern(40)[10..<10]
check(emptySlice.span.count == 0 && emptySlice.mutableSpan.count == 0, "an empty slice gives empty spans")

// An empty slice that does not start at index 0 stays a slice that shares its parent's storage. While the parent is
// alive, the mutable accessors must give an empty span and leave the parent alone (the parent is used after the calls).
let liveParent = pattern(40)
var liveEmpty = liveParent[10..<10]
check(liveEmpty.mutableSpan.count == 0, "mutableSpan of an empty slice whose parent is alive is empty")
check(liveEmpty.mutableBytes.byteCount == 0, "mutableBytes of an empty slice whose parent is alive is empty")
check(liveEmpty.isEmpty && liveEmpty.startIndex == 10 && liveParent == pattern(40),
    "an empty slice whose parent is alive keeps its index and its parent")
let liveParent2 = pattern(100_000)
var liveEmpty2 = liveParent2[500..<500]
check(liveEmpty2.mutableSpan.count == 0 && liveEmpty2.mutableBytes.byteCount == 0 && liveParent2.count == 100_000,
    "mutable spans of an empty slice of a 100 000-byte parent that is alive are empty")

// Inline (1 to 14 bytes), slice (15 and up) and large sizes: the spans show the bytes of the Data.
for n in Array(1...16) + [100_000] {
    let d = pattern(n)
    check(d.bytes.byteCount == n && d.span.count == n, "span sizes for \(n) bytes")
    check(viaBytes(d) == Array(d) && viaSpan(d) == Array(d), "span contents for \(n) bytes")
}

// A slice whose startIndex is not 0, small and large
for (total, range) in [(40, 10..<25), (100_000, 99_000..<99_010), (100_000, 5..<99_995)] {
    let base = pattern(total)
    let part = base[range]
    check(part.startIndex == range.lowerBound, "slice \(range) keeps its start index")
    check(part.bytes.byteCount == range.count && part.span.count == range.count, "slice \(range) span sizes")
    check(viaBytes(part) == Array(part) && viaSpan(part) == Array(part), "slice \(range) span contents")
}

// Writes through the mutable spans are visible in the Data, at the right offset
for n in [1, 14, 15, 16, 100_000] {
    var d = pattern(n)
    var expected = Array(d)
    check(d.mutableSpan.count == n && d.mutableBytes.byteCount == n, "mutable span sizes for \(n) bytes")
    writeViaMutableSpan(&d, at: n - 1, 0xAB)
    writeViaMutableBytes(&d, at: 0, 0xCD)
    expected[n - 1] = 0xAB
    expected[0] = 0xCD
    check(Array(d) == expected && d.count == n, "writes through mutable spans for \(n) bytes")
}

// Copy on write: a copy taken before the write keeps the old bytes, and a slice leaves the Data it was cut from alone
var original = pattern(100)
let copy = original
writeViaMutableSpan(&original, at: 3, 0xEE)
check(copy == pattern(100) && original[3] == 0xEE, "mutableSpan copies a shared Data first")
var original2 = pattern(100)
let copy2 = original2
writeViaMutableBytes(&original2, at: 3, 0xEE)
check(copy2 == pattern(100) && original2[3] == 0xEE, "mutableBytes copies a shared Data first")
let big = pattern(100_000)
var part = big[500..<600]
writeViaMutableSpan(&part, at: 0, 0x55)
check(part[500] == 0x55 && big[500] == pattern(100_000)[500], "writing to a slice leaves its parent unchanged")

// NSMutableData bridging: a Data made from an NSMutableData is a copy, so a write leaves the NSMutableData unchanged
let source = pattern(100)
let mutable = NSMutableData(bytes: Array(source), length: 100)!
var bridged = mutable as Data
writeViaMutableSpan(&bridged, at: 0, 0x99)
check(bridged[0] == 0x99 && Data(referencing: mutable) == source && mutable.length() == 100,
    "writing to a Data bridged from NSMutableData leaves the NSMutableData unchanged")
check(viaBytes(mutable as Data) == Array(source), "bytes of a Data bridged from NSMutableData")

// Immutable NSData: Data is a value type, so a write through a mutable span must never reach the NSData that
// Data(referencing:) wraps (the documentation of Data(referencing:) says a mutated Data copies the contents first).
func contents(_ nsdata: NSData) -> [UInt8] {
    Array(UnsafeRawBufferPointer(start: nsdata.bytes, count: nsdata.length()))
}
func edited(_ bytes: [UInt8], _ index: Int, _ value: UInt8) -> [UInt8] {
    var copy = bytes
    copy[index] = value
    return copy
}
// 1 and 14 bytes are stored inline by Data(referencing:), a copy by construction: those two sizes are GUARDS (they cannot
// fail, and pass in every variant of the module). 15 and 100_000 bytes are the cases that fail without the helper fix.
for n in [1, 14, 15, 100_000] {
    let expected = Array(pattern(n))
    let nsdata = (NSData(bytes: expected, length: n) as NSData?)!
    var referencing = Data(referencing: nsdata)
    check(Array(referencing) == expected, "Data(referencing:) shows the NSData bytes for \(n) bytes")
    writeViaMutableSpan(&referencing, at: n - 1, 0x99)
    check(Array(referencing) == edited(expected, n - 1, 0x99), "mutableSpan write on a Data made from an NSData, \(n) bytes")
    check(contents(nsdata) == expected, "mutableSpan write leaves the NSData unchanged for \(n) bytes")
    writeViaMutableBytes(&referencing, at: 0, 0x98)
    check(contents(nsdata) == expected, "mutableBytes write leaves the NSData unchanged for \(n) bytes")
    check(Array(Data(referencing: nsdata)) == expected, "a Data made from the NSData afterwards sees the original bytes, \(n) bytes")
}

// Round trip: Data(referencing:) bridged to NSData and back to Data. Writes through any of the Data values must not show
// in another one, in the NSData in the middle, or in the first NSData. The hop goes through an NSArray in a function
// that is never inlined, so that the compiler cannot cancel the two bridge calls: the direct `(first as NSData) as Data`
// was not seen to alias in a Darling guest; neither was this form. This file never calls withUnsafeMutableBytes, so
// these cases say nothing about the wumb fix; their 15 and 100 000 byte lines do fail without the helper fix (cause not isolated).
// 1 and 14 bytes are inline: GUARDS, as above.
@inline(never) func throughNSArray(_ nsdata: NSData) -> NSData {
    NSArray(object: nsdata)[0] as! NSData
}
for n in [1, 14, 15, 100_000] {
    let expected = Array(pattern(n))
    let nsdata = (NSData(bytes: expected, length: n) as NSData?)!
    var first = Data(referencing: nsdata)
    var second = first
    let back = throughNSArray(first as NSData)
    var third = back as Data
    writeViaMutableSpan(&second, at: 0, 0x11)
    writeViaMutableSpan(&third, at: n - 1, 0x22)
    check(Array(second) == edited(expected, 0, 0x11) && Array(third) == edited(expected, n - 1, 0x22),
        "round trip: each Data sees only its own write, \(n) bytes")
    check(Array(first) == expected && contents(back) == expected && contents(nsdata) == expected,
        "round trip: the first Data and both NSData are unchanged after writes to the others, \(n) bytes")
    writeViaMutableBytes(&first, at: 0, 0x33)
    check(Array(first) == edited(expected, 0, 0x33) && contents(back) == expected && contents(nsdata) == expected,
        "round trip: a write to the first Data reaches neither NSData, \(n) bytes")
}

// A slice of Data(referencing:) whose parent is gone: the slice alone holds the storage (unique, startIndex != 0), so
// only the storage's own capacity, not its reference count, says that the bytes belong to the NSData.
for (total, range) in [(40, 5..<12), (100_000, 500..<600)] {
    let expected = Array(pattern(total))
    let nsdata = (NSData(bytes: expected, length: total) as NSData?)!
    var slice = Data(referencing: nsdata)[range]
    writeViaMutableSpan(&slice, at: 1, 0x77)
    var edit = expected
    edit[range.lowerBound + 1] = 0x77
    check(contents(nsdata) == expected, "a write to a referencing slice leaves the NSData unchanged, \(total) bytes")
    check(slice.startIndex == range.lowerBound && slice.count == range.count && Array(slice) == Array(edit[range]),
        "a referencing slice keeps its indices and shows its own write, \(total) bytes")
    writeViaMutableBytes(&slice, at: 0, 0x66)
    check(contents(nsdata) == expected && slice[range.lowerBound] == 0x66, "mutableBytes on a referencing slice, \(total) bytes")
}

// bytesNoCopy: the Data borrows the caller's buffer and runs the deallocator when it goes away
var deallocations = 0
func writeToBorrowedBuffer() -> UInt8 {
    let buffer = UnsafeMutableRawPointer.allocate(byteCount: 100, alignment: 1)
    buffer.initializeMemory(as: UInt8.self, repeating: 3, count: 100)
    var d = Data(bytesNoCopy: buffer, count: 100, deallocator: .custom({ pointer, _ in
        pointer.deallocate()
        deallocations += 1
    }))
    check(d.span.count == 100 && d.bytes.byteCount == 100, "bytesNoCopy span sizes")
    writeViaMutableSpan(&d, at: 99, 0x42)
    return d[99]
}
check(writeToBorrowedBuffer() == 0x42, "mutableSpan on a bytesNoCopy Data")
check(deallocations == 1, "the bytesNoCopy deallocator ran once")

// A Data of Int32.max bytes or more is held by a LargeSlice; the memory is untouched except for two bytes
let largeCount = Int(Int32.max)
if let memory = calloc(largeCount, 1) {
    var huge = Data(bytesNoCopy: memory, count: largeCount, deallocator: .free)
    check(huge.span.count == largeCount && huge.bytes.byteCount == largeCount, "span sizes of a Data of Int32.max bytes")
    writeViaMutableSpan(&huge, at: largeCount - 1, 0x7F)
    writeViaMutableBytes(&huge, at: 0, 0x01)
    check(huge[0] == 0x01 && huge[largeCount - 1] == 0x7F && huge[1] == 0, "writes into a Data of Int32.max bytes")
} else {
    print("skip: calloc of Int32.max bytes failed, the LargeSlice case was not run")
}

// The same size through Data(referencing:): a write copies the 2 GiB first, so the original bytes stay unchanged. The
// copy needs as much memory again; the case is skipped when that is not available.
if let probe = malloc(largeCount) {
    free(probe)
    if let memory = calloc(largeCount, 1) {
        let nsdata = (NSData(bytesNoCopy: memory, length: largeCount, freeWhenDone: false) as NSData?)!
        var referencing = Data(referencing: nsdata)
        check(referencing.span.count == largeCount, "span size of a Data of Int32.max bytes made from an NSData")
        writeViaMutableSpan(&referencing, at: largeCount - 1, 0x7F)
        check(referencing[largeCount - 1] == 0x7F && referencing[0] == 0, "a Data of Int32.max bytes made from an NSData shows its own write")
        check(memory.load(fromByteOffset: largeCount - 1, as: UInt8.self) == 0 && nsdata.length() == largeCount,
            "a write to a Data of Int32.max bytes made from an NSData leaves the NSData unchanged")
        referencing = Data()
        free(memory)
    } else {
        print("skip: calloc of Int32.max bytes failed, the referencing LargeSlice case was not run")
    }
} else {
    print("skip: no room for a second Int32.max-byte buffer, the referencing LargeSlice case was not run")
}

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
