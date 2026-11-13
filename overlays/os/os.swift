//===----------------------------------------------------------------------===//
//
// os Swift overlay for Darling.
//
// Written from Apple's public API documentation for the os framework and the
// symbol names/signatures that macOS binaries import. No Apple code is used.
// Logging is forwarded to libsystem_trace's _os_log_impl using the public
// os_log buffer layout understood by Darling's decoder.
//
//===----------------------------------------------------------------------===//

@_exported import os // Clang module
@_implementationOnly import _DarlingOSShims
import Darwin

// MARK: - OSLog

extension OSLog {
	public static var `default`: OSLog {
		return _darling_os_log_default()
	}

	public static var disabled: OSLog {
		return _darling_os_log_disabled()
	}

	public convenience init(subsystem: String, category: String) {
		self.init(__subsystem: subsystem, category: category)
	}

	// Darling's libsystem_trace has no signpost backend (its signpost entry points abort), so
	// signposts are reported as disabled and never reach it.
	public var signpostsEnabled: Bool {
		return false
	}
}

extension OSLogType {
	public static var `default`: OSLogType { return OSLogType(rawValue: 0x00) }
	public static var info: OSLogType { return OSLogType(rawValue: 0x01) }
	public static var debug: OSLogType { return OSLogType(rawValue: 0x02) }
	public static var error: OSLogType { return OSLogType(rawValue: 0x10) }
	public static var fault: OSLogType { return OSLogType(rawValue: 0x11) }
}

// Values from the macOS SDK's <os/signpost.h>; binaries built against it pass these.
extension OSSignpostType {
	public static var event: OSSignpostType { return OSSignpostType(rawValue: 0x00) }
	public static var begin: OSSignpostType { return OSSignpostType(rawValue: 0x01) }
	public static var end: OSSignpostType { return OSSignpostType(rawValue: 0x02) }
}

// MARK: - os_log buffer encoding

/// Encodes printf-style arguments into the os_log argument buffer:
/// `[summary][count]` followed by `[type << 4 | privacy][size][bytes...]` per argument.
internal struct _OSLogArgumentBuffer {
	enum ItemType: UInt8 {
		case scalar = 0, count = 1, string = 2, pointer = 3, object = 4, wideString = 5, errno = 6
	}

	var bytes: [UInt8] = [0, 0]

	mutating func append(type: ItemType, privacy: UInt8, size: Int, word: UInt64) {
		bytes.append(type.rawValue << 4 | privacy)
		bytes.append(UInt8(size))
		var value = word
		withUnsafeBytes(of: &value) { raw in
			bytes.append(contentsOf: raw.prefix(size))
		}
		bytes[1] &+= 1
	}

	init(format: UnsafePointer<CChar>, arguments: [CVarArg]) {
		var argumentIndex = 0
		func nextWord() -> UInt64 {
			guard argumentIndex < arguments.count else { return 0 }
			defer { argumentIndex += 1 }
			return UInt64(bitPattern: Int64(arguments[argumentIndex]._cVarArgEncoding.first ?? 0))
		}

		var p = format
		while p.pointee != 0 {
			guard p.pointee == 0x25 /* % */ else { p += 1; continue }
			p += 1
			if p.pointee == 0x25 { p += 1; continue } // "%%"

			var privacy: UInt8 = 0
			if p.pointee == 0x7B /* { */ {
				var annotation = ""
				p += 1
				while p.pointee != 0 && p.pointee != 0x7D /* } */ {
					annotation.unicodeScalars.append(Unicode.Scalar(UInt8(bitPattern: p.pointee)))
					p += 1
				}
				if p.pointee == 0x7D { p += 1 }
				if annotation.contains("public") {
					privacy = 2
				} else if annotation.contains("private") {
					privacy = 1
				}
			}

			// Flags, width and precision; '*' takes an argument.
			while let c = Optional(p.pointee), c == 0x2D || c == 0x2B || c == 0x20 || c == 0x23 || c == 0x30
				|| c == 0x2E || c == 0x2A || (c >= 0x31 && c <= 0x39) {
				if c == 0x2A {
					append(type: .count, privacy: 0, size: 4, word: nextWord())
				}
				p += 1
			}

			var longSize = false
			while let c = Optional(p.pointee), c == 0x68 || c == 0x6C || c == 0x71 || c == 0x6A || c == 0x7A || c == 0x74 || c == 0x4C {
				if c != 0x68 { longSize = true }
				p += 1
			}

			switch p.pointee {
			case 0x73: // s
				append(type: .string, privacy: privacy, size: 8, word: nextWord())
			case 0x53: // S
				append(type: .wideString, privacy: privacy, size: 8, word: nextWord())
			case 0x40: // @
				append(type: .object, privacy: privacy, size: 8, word: nextWord())
			case 0x70: // p
				append(type: .pointer, privacy: privacy, size: 8, word: nextWord())
			case 0x66, 0x46, 0x65, 0x45, 0x67, 0x47, 0x61, 0x41: // floating point
				append(type: .scalar, privacy: privacy, size: 8, word: nextWord())
			case 0x6D: // m
				append(type: .errno, privacy: privacy, size: 4, word: UInt64(UInt32(bitPattern: errno)))
			case 0:
				return
			default: // integers and characters
				append(type: .scalar, privacy: privacy, size: longSize ? 8 : 4, word: nextWord())
			}
			p += 1
		}
	}
}

internal func _withCString<R>(_ string: StaticString, _ body: (UnsafePointer<CChar>) -> R) -> R {
	if string.hasPointerRepresentation {
		return string.utf8Start.withMemoryRebound(to: CChar.self, capacity: string.utf8CodeUnitCount + 1, body)
	}
	return String(describing: string).withCString(body)
}

internal func _emitLog(_ message: StaticString, dso: UnsafeRawPointer?, log: OSLog, type: OSLogType, arguments: [CVarArg]) {
	guard log.isEnabled(type: type) else { return }
	_withCString(message) { format in
		var buffer = _OSLogArgumentBuffer(format: format, arguments: arguments)
		withExtendedLifetime(arguments) {
			buffer.bytes.withUnsafeMutableBufferPointer { bytes in
				_darling_os_log_impl(UnsafeMutableRawPointer(mutating: dso), log, type, format, bytes.baseAddress, UInt32(bytes.count))
			}
		}
	}
}

public func os_log(_ message: StaticString, dso: UnsafeRawPointer? = #dsohandle, log: OSLog = .default,
		type: OSLogType = .default, _ args: CVarArg...) {
	_emitLog(message, dso: dso, log: log, type: type, arguments: args)
}

public func os_log(_ type: OSLogType, dso: UnsafeRawPointer = #dsohandle, log: OSLog = .default,
		_ message: StaticString, _ args: CVarArg...) {
	_emitLog(message, dso: dso, log: log, type: type, arguments: args)
}

// MARK: - Signposts

internal let _nextSignpostID = OSAllocatedUnfairLock<UInt64>(initialState: 0x1000)

public struct OSSignpostID {
	public let rawValue: UInt64

	public init(_ value: UInt64) {
		rawValue = value
	}

	public init(log: OSLog) {
		rawValue = _nextSignpostID.withLock { value in
			value &+= 1
			return value
		}
	}

	public init(log: OSLog, object: AnyObject) {
		// Like os_signpost_id_make_with_pointer: derived from the address, never NULL/INVALID/EXCLUSIVE.
		let address = UInt64(UInt(bitPattern: Unmanaged.passUnretained(object).toOpaque()))
		switch address {
		case 0, ~0, 0xEEEE_B0B5_B2B2_EEEE: rawValue = 1
		default: rawValue = address
		}
	}

	// OS_SIGNPOST_ID_EXCLUSIVE, OS_SIGNPOST_ID_INVALID and OS_SIGNPOST_ID_NULL from the macOS SDK.
	public static var exclusive: OSSignpostID { return OSSignpostID(0xEEEE_B0B5_B2B2_EEEE) }
	public static var invalid: OSSignpostID { return OSSignpostID(~0) }
	public static var null: OSSignpostID { return OSSignpostID(0) }
}

extension OSSignpostID: Equatable, Comparable, Hashable {
	public static func == (lhs: OSSignpostID, rhs: OSSignpostID) -> Bool {
		return lhs.rawValue == rhs.rawValue
	}

	public static func < (lhs: OSSignpostID, rhs: OSSignpostID) -> Bool {
		return lhs.rawValue < rhs.rawValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(rawValue)
	}
}

internal func _emitSignpost(_ type: OSSignpostType, dso: UnsafeRawPointer?, log: OSLog, name: StaticString,
		signpostID: OSSignpostID, format: StaticString?, arguments: [CVarArg]) {
	// No signpost backend in Darling (see OSLog.signpostsEnabled).
	guard log.signpostsEnabled else { return }
}

public func os_signpost(_ type: OSSignpostType, dso: UnsafeRawPointer = #dsohandle, log: OSLog, name: StaticString,
		signpostID: OSSignpostID = .exclusive) {
	_emitSignpost(type, dso: dso, log: log, name: name, signpostID: signpostID, format: nil, arguments: [])
}

public func os_signpost(_ type: OSSignpostType, dso: UnsafeRawPointer = #dsohandle, log: OSLog, name: StaticString,
		signpostID: OSSignpostID = .exclusive, _ format: StaticString, _ arguments: CVarArg...) {
	_emitSignpost(type, dso: dso, log: log, name: name, signpostID: signpostID, format: format, arguments: arguments)
}

// MARK: - Logger

public struct Logger {
	public let logObject: OSLog

	public init(subsystem: String, category: String) {
		logObject = OSLog(subsystem: subsystem, category: category)
	}

	public init() {
		logObject = .default
	}

	public init(_ logObj: OSLog) {
		logObject = logObj
	}
}

// MARK: - OSSignposter

public enum OSSignpostError: Error {
	case doubleEnd
	/// Returned by `checkForErrorAndConsumeState(state:)` when the interval was still open.
	case _noError
}

public final class OSSignpostIntervalState {
	public let signpostID: OSSignpostID
	// Heap-allocated so the lock has a stable address (`&storedProperty` isn't guaranteed to be one).
	private let lock: UnsafeMutablePointer<os_unfair_lock>
	private var isOpen: Bool

	public init(id: OSSignpostID, isOpen: Bool) {
		signpostID = id
		self.isOpen = isOpen
		lock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
		lock.initialize(to: os_unfair_lock())
	}

	deinit {
		lock.deinitialize(count: 1)
		lock.deallocate()
	}

	fileprivate func consume() -> Bool {
		os_unfair_lock_lock(lock)
		defer { os_unfair_lock_unlock(lock) }
		let wasOpen = isOpen
		isOpen = false
		return wasOpen
	}
}

public func checkForErrorAndConsumeState(state: OSSignpostIntervalState) -> OSSignpostError {
	return state.consume() ? ._noError : .doubleEnd
}

public struct OSSignposter {
	public let logHandle: OSLog

	public init(subsystem: String, category: String) {
		logHandle = OSLog(subsystem: subsystem, category: category)
	}

	public init(logger: Logger) {
		logHandle = logger.logObject
	}

	public init(logHandle: OSLog) {
		self.logHandle = logHandle
	}

	public init() {
		logHandle = .disabled
	}

	public var isEnabled: Bool {
		return logHandle.signpostsEnabled
	}

	public func makeSignpostID() -> OSSignpostID {
		return OSSignpostID(log: logHandle)
	}

	public func makeSignpostID(from object: AnyObject) -> OSSignpostID {
		return OSSignpostID(log: logHandle, object: object)
	}

	public func emitEvent(_ name: StaticString, id: OSSignpostID = .exclusive) {
		os_signpost(.event, log: logHandle, name: name, signpostID: id)
	}

	public func beginInterval(_ name: StaticString, id: OSSignpostID = .exclusive) -> OSSignpostIntervalState {
		os_signpost(.begin, log: logHandle, name: name, signpostID: id)
		return OSSignpostIntervalState(id: id, isOpen: true)
	}

	public func endInterval(_ name: StaticString, _ state: OSSignpostIntervalState) {
		if case .doubleEnd = checkForErrorAndConsumeState(state: state) {
			return
		}
		os_signpost(.end, log: logHandle, name: name, signpostID: state.signpostID)
	}
}

// MARK: - OSAllocatedUnfairLock

public struct OSAllocatedUnfairLock<State>: @unchecked Sendable {
	@usableFromInline
	internal let _buffer: ManagedBuffer<State, os_unfair_lock>

	public init(uncheckedState initialState: State) {
		_buffer = ManagedBuffer<State, os_unfair_lock>.create(minimumCapacity: 1) { buffer in
			buffer.withUnsafeMutablePointerToElements { $0.initialize(to: os_unfair_lock()) }
			return initialState
		}
	}

	public init(initialState: State) {
		self.init(uncheckedState: initialState)
	}

	public func withLockUnchecked<R>(_ body: (inout State) throws -> R) rethrows -> R {
		return try _buffer.withUnsafeMutablePointers { state, lock in
			os_unfair_lock_lock(lock)
			defer { os_unfair_lock_unlock(lock) }
			return try body(&state.pointee)
		}
	}

	public func withLock<R>(_ body: (inout State) throws -> R) rethrows -> R {
		return try withLockUnchecked(body)
	}

	public func withLockIfAvailableUnchecked<R>(_ body: (inout State) throws -> R) rethrows -> R? {
		return try _buffer.withUnsafeMutablePointers { state, lock in
			guard os_unfair_lock_trylock(lock) else { return nil }
			defer { os_unfair_lock_unlock(lock) }
			return try body(&state.pointee)
		}
	}

	public func lock() {
		_buffer.withUnsafeMutablePointerToElements { os_unfair_lock_lock($0) }
	}

	public func unlock() {
		_buffer.withUnsafeMutablePointerToElements { os_unfair_lock_unlock($0) }
	}

	public func lockIfAvailable() -> Bool {
		return _buffer.withUnsafeMutablePointerToElements { os_unfair_lock_trylock($0) }
	}
}

extension OSAllocatedUnfairLock where State == () {
	public init() {
		self.init(uncheckedState: ())
	}

	public func withLockUnchecked<R>(_ body: () throws -> R) rethrows -> R {
		return try withLockUnchecked { (_: inout ()) in try body() }
	}

	public func withLock<R>(_ body: () throws -> R) rethrows -> R {
		return try withLockUnchecked { (_: inout ()) in try body() }
	}
}
