//===----------------------------------------------------------------------===//
//
// XPC Swift overlay for Darling.
//
// Written from Apple's public API documentation (macOS 14 XPC Swift API) and the
// symbol names/signatures that macOS binaries import. No Apple code is used.
// Implemented on top of libxpc's C API.
//
//===----------------------------------------------------------------------===//

@_exported import XPC // Clang module
@_implementationOnly import _SwiftXPCOverlayShims
@_implementationOnly import _DarlingXPCShims
import Dispatch

/// Reference box so XPCDictionary/XPCArray can copy their XPC object on write.
internal final class _XPCObjectBox {
	var object: xpc_object_t

	init(_ object: xpc_object_t) {
		self.object = object
	}
}

internal func _isType(_ object: xpc_object_t, _ type: xpc_type_t) -> Bool {
	return _swift_xpc_get_type(object) == type
}

// MARK: - XPCRichError

public struct XPCRichError: Error, CustomStringConvertible {
	public let description: String
	public let canRetry: Bool

	internal init(_ error: xpc_object_t) {
		if let message = xpc_dictionary_get_string(error, _xpc_error_key_description) {
			description = String(cString: message)
		} else {
			description = "XPC error"
		}
		canRetry = error === _swift_xpc_connection_interrupted()!
	}

	internal init(description: String, canRetry: Bool = false) {
		self.description = description
		self.canRetry = canRetry
	}
}

// MARK: - XPCDictionary

public struct XPCDictionary {
	internal var _box: _XPCObjectBox

	public init() {
		_box = _XPCObjectBox(xpc_dictionary_create(nil, nil, 0)!)
	}

	public init(fromXPCObject object: xpc_object_t) {
		precondition(_isType(object, _swift_xpc_type_DICTIONARY()), "not an XPC dictionary")
		_box = _XPCObjectBox(object)
	}

	internal mutating func _mutableObject() -> xpc_object_t {
		if !isKnownUniquelyReferenced(&_box) {
			_box = _XPCObjectBox(xpc_copy(_box.object)!)
		}
		return _box.object
	}

	internal func _value(_ key: String) -> xpc_object_t? {
		return xpc_dictionary_get_value(_box.object, key)
	}

	public var count: Int {
		return xpc_dictionary_get_count(_box.object)
	}

	public var isEmpty: Bool {
		return count == 0
	}

	public func withUnsafeUnderlyingDictionary<Result>(_ body: (xpc_object_t) throws -> Result) rethrows -> Result {
		return try body(_box.object)
	}

	public subscript(key: String) -> xpc_object_t? {
		get {
			return _value(key)
		}
		set {
			xpc_dictionary_set_value(_mutableObject(), key, newValue)
		}
	}

	public subscript(key: String) -> Bool? {
		get {
			guard let value = _value(key), _isType(value, _swift_xpc_type_BOOL()) else { return nil }
			return xpc_bool_get_value(value)
		}
		set {
			if let newValue {
				xpc_dictionary_set_bool(_mutableObject(), key, newValue)
			} else {
				xpc_dictionary_set_value(_mutableObject(), key, nil)
			}
		}
	}

	public subscript(key: String) -> String? {
		get {
			guard let value = _value(key), _isType(value, _swift_xpc_type_STRING()),
				let cString = xpc_string_get_string_ptr(value) else { return nil }
			return String(cString: cString)
		}
		set {
			if let newValue {
				xpc_dictionary_set_string(_mutableObject(), key, newValue)
			} else {
				xpc_dictionary_set_value(_mutableObject(), key, nil)
			}
		}
	}

	public subscript<T: SignedInteger>(key: String) -> T? {
		get {
			guard let value = _value(key) else { return nil }
			if _isType(value, _swift_xpc_type_INT64()) {
				return T(exactly: xpc_int64_get_value(value))
			}
			if _isType(value, _swift_xpc_type_UINT64()) {
				return T(exactly: xpc_uint64_get_value(value))
			}
			return nil
		}
		set {
			if let newValue {
				xpc_dictionary_set_int64(_mutableObject(), key, Int64(newValue))
			} else {
				xpc_dictionary_set_value(_mutableObject(), key, nil)
			}
		}
	}

	public subscript<T: UnsignedInteger>(key: String) -> T? {
		get {
			guard let value = _value(key) else { return nil }
			if _isType(value, _swift_xpc_type_UINT64()) {
				return T(exactly: xpc_uint64_get_value(value))
			}
			if _isType(value, _swift_xpc_type_INT64()) {
				return T(exactly: xpc_int64_get_value(value))
			}
			return nil
		}
		set {
			if let newValue {
				xpc_dictionary_set_uint64(_mutableObject(), key, UInt64(newValue))
			} else {
				xpc_dictionary_set_value(_mutableObject(), key, nil)
			}
		}
	}

	public subscript(key: String) -> XPCDictionary? {
		get {
			guard let value = _value(key), _isType(value, _swift_xpc_type_DICTIONARY()) else { return nil }
			return XPCDictionary(fromXPCObject: value)
		}
		set {
			xpc_dictionary_set_value(_mutableObject(), key, newValue?._box.object)
		}
	}

	public subscript(key: String) -> XPCArray? {
		get {
			guard let value = _value(key), _isType(value, _swift_xpc_type_ARRAY()) else { return nil }
			return XPCArray(fromXPCObject: value)
		}
		set {
			xpc_dictionary_set_value(_mutableObject(), key, newValue?._box.object)
		}
	}
}

// MARK: - XPCArray

public struct XPCArray {
	internal var _box: _XPCObjectBox

	public init() {
		_box = _XPCObjectBox(xpc_array_create(nil, 0)!)
	}

	public init(fromXPCObject object: xpc_object_t) {
		precondition(_isType(object, _swift_xpc_type_ARRAY()), "not an XPC array")
		_box = _XPCObjectBox(object)
	}

	internal mutating func _mutableObject() -> xpc_object_t {
		if !isKnownUniquelyReferenced(&_box) {
			_box = _XPCObjectBox(xpc_copy(_box.object)!)
		}
		return _box.object
	}

	public var count: Int {
		return xpc_array_get_count(_box.object)
	}

	public mutating func append(_ value: xpc_object_t) {
		xpc_array_append_value(_mutableObject(), value)
	}

	public func withUnsafeUnderlyingArray<Result>(_ body: (xpc_object_t) throws -> Result) rethrows -> Result {
		return try body(_box.object)
	}
}

// MARK: - XPCSession

public class XPCSession {
	public struct InitializationOptions: OptionSet {
		public let rawValue: UInt64

		public init(rawValue: UInt64) {
			self.rawValue = rawValue
		}

		public static var none: InitializationOptions {
			return InitializationOptions(rawValue: 0)
		}

		public static var inactive: InitializationOptions {
			return InitializationOptions(rawValue: 1 << 0)
		}
	}

	internal let _connection: xpc_connection_t
	internal let _targetQueue: DispatchQueue?

	public init(machService: String, targetQueue: DispatchQueue? = nil, options: InitializationOptions = .none,
			cancellationHandler: ((XPCRichError) -> Void)? = nil) throws {
		guard let connection = xpc_connection_create_mach_service(machService, targetQueue, 0) else {
			throw XPCRichError(description: "failed to create a connection to \(machService)")
		}
		_connection = connection
		_targetQueue = targetQueue
		xpc_connection_set_event_handler(connection) { event in
			guard let event else { return }
			if _isType(event, _swift_xpc_type_ERROR()), event !== _swift_xpc_connection_interrupted()! {
				cancellationHandler?(XPCRichError(event))
			}
		}
		if !options.contains(.inactive) {
			xpc_connection_resume(connection)
		}
	}

	public func activate() throws {
		xpc_connection_resume(_connection)
	}

	public func send(message: XPCDictionary, replyHandler: @escaping (Result<XPCDictionary, XPCRichError>) -> Void) {
		// Darling's libxpc needs an explicit reply queue; macOS uses the connection's target queue for NULL.
		xpc_connection_send_message_with_reply(_connection, message._box.object, _targetQueue ?? DispatchQueue.global()) { reply in
			guard let reply else {
				replyHandler(.failure(XPCRichError(description: "no reply")))
				return
			}
			if _isType(reply, _swift_xpc_type_DICTIONARY()) {
				replyHandler(.success(XPCDictionary(fromXPCObject: reply)))
			} else {
				replyHandler(.failure(XPCRichError(reply)))
			}
		}
	}

	public func send(message: XPCDictionary) throws {
		xpc_connection_send_message(_connection, message._box.object)
	}

	public func cancel(reason: String) {
		xpc_connection_cancel(_connection)
	}

	deinit {
		xpc_connection_cancel(_connection)
	}
}
