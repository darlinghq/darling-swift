// Copyright (C) 2026 Lubos Dolezel
//
// NSData.bytes is declared nonnull in the macOS SDK, so Swift imports it as UnsafeRawPointer (not an optional). The
// Swift-backed NSData that `Data as NSData` produces must follow that, and the DataProtocol members of NSData that read
// the pointer must work without unwrapping it.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

// Compile-time: this only builds while `bytes` is a non-optional UnsafeRawPointer.
func pointerType(_ pointer: UnsafeRawPointer) -> String { "UnsafeRawPointer" }

for n in [1, 14, 15, 100_000] {
    let expected = (0..<n).map { UInt8(truncatingIfNeeded: $0 &* 7 &+ 1) }
    let nsdata = Data(expected) as NSData
    let pointer = nsdata.bytes
    check(pointerType(pointer) == "UnsafeRawPointer", "bytes is an UnsafeRawPointer, \(n) bytes")
    check(pointer.load(fromByteOffset: n - 1, as: UInt8.self) == expected[n - 1], "pointer arithmetic on bytes reads the last byte, \(n) bytes")
    check(Array(UnsafeRawBufferPointer(start: nsdata.bytes, count: nsdata.length())) == expected, "bytes holds the contents, \(n) bytes")
    check(nsdata[n - 1] == expected[n - 1] && nsdata[0] == expected[0], "NSData DataProtocol subscript reads through bytes, \(n) bytes")
    check(nsdata.regions.count == 1 && Array(nsdata.regions[0]) == expected, "NSData DataProtocol regions covers the contents, \(n) bytes")
}

// An empty Data still gives a pointer, which must not be read (the length is zero).
let empty = Data() as NSData
check(empty.length() == 0 && pointerType(empty.bytes) == "UnsafeRawPointer", "empty Data gives a pointer of length 0")
check(empty.regions.isEmpty, "empty NSData has no regions")

// A slice of a Data: bytes starts at the slice, not at the parent.
let parent = Data((0..<100).map { UInt8($0) })
let slice = (parent[40..<60] as Data) as NSData
check(slice.bytes.load(as: UInt8.self) == 40 && slice.length() == 20, "bytes of a slice points at the slice")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
