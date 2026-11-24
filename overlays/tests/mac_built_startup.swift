// Copyright (C) 2026 Lubos Dolezel
//
// Licensed under the MIT license, the same as the rest of this project.
//
// A program built on a Mac for macOS 10.15 (swiftc -target x86_64-apple-macosx10.15 mac_built_startup.swift) starts in the
// guest, with no DYLD_* variable, and gets to use Foundation's Swift overlay: dyld binds the overlay's imports
// (the error domains and keys, ...) by library ordinal, so a symbol that the library it names does not export
// makes the program abort before main. Prints PASS.
import Foundation

var failures = 0
func expect(_ condition: Bool, _ what: String) { if !condition { print("FAIL \(what)"); failures += 1 } }

expect(NSCocoaErrorDomain == "NSCocoaErrorDomain", "NSCocoaErrorDomain")
expect(NSPOSIXErrorDomain == "NSPOSIXErrorDomain", "NSPOSIXErrorDomain")
let error = CocoaError(.fileReadUnknown, userInfo: [NSFilePathErrorKey: "/tmp/example.txt", NSLocalizedFailureReasonErrorKey: "Because."])
expect((error as NSError).code == 256, "CocoaError code")
expect((error as NSError).localizedFailureReason == "Because.", "failure reason from the userInfo")
expect((error as NSError).userInfo[NSFilePathErrorKey] as? String == "/tmp/example.txt", "path key")
expect(CocoaError.errorDomain == "NSCocoaErrorDomain", "CocoaError.errorDomain")
print(failures == 0 ? "PASS" : "FAIL (\(failures))")
exit(failures == 0 ? 0 : 1)
