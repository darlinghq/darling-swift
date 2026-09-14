@_exported import Foundation // Clang module
@_spi(Foundation) import Swift

extension String {
  public init(_ cocoaString: NSString) {
    self = String(_cocoaString: cocoaString)
  }
}

extension String : _ObjectiveCBridgeable {
  @_semantics("convertToObjectiveC")
  public func _bridgeToObjectiveC() -> NSString {
    return unsafeBitCast(_bridgeToObjectiveCImpl(), to: NSString.self)
  }

  public static func _forceBridgeFromObjectiveC(_ x: NSString, result: inout String?) {
    result = String(x)
  }

  public static func _conditionallyBridgeFromObjectiveC(_ x: NSString, result: inout String?) -> Bool {
    self._forceBridgeFromObjectiveC(x, result: &result)
    return result != nil
  }

  public static func _unconditionallyBridgeFromObjectiveC(_ source: NSString?) -> String {
    if _slowPath(source == nil) { return String() }
    return String(source!)
  }
}

// The stdlib's StringBridge sends this to NSObject when bridging small ASCII strings (from the 5.4 overlay).
private extension NSObject {
  // The selector starts with "new" so ARC returns it +1.
  @_effects(releasenone)
  @objc(newTaggedNSStringWithASCIIBytes_:length_:)
  func createTaggedString(bytes: UnsafePointer<UInt8>, count: Int) -> AnyObject? {
    return NSString(bytes: bytes, length: count, encoding: UInt(NSUTF8StringEncoding))
  }
}
