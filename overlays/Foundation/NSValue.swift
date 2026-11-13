//===--- NSValue.swift - Bridging things in NSValue -----------*- swift -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

// Generated from release/5.4 (apple/swift 845205b4407c) stdlib/public/Darwin/Foundation/NSValue.swift.gyb by utils/gyb.py
// (utils/gyb_foundation_support.py of the same commit). Darling: NSValue's objCType is a method, and the getValue:size:
// variant of the pre-10.13 fallback is not declared, so the plain getValue: of the original's else branch is used.

@_exported import Foundation // Clang module
import CoreGraphics


extension NSRange: _ObjectiveCBridgeable {
  public func _bridgeToObjectiveC() -> NSValue {
    var myself = self
    return NSValue(bytes: &myself, objCType: _getObjCTypeEncoding(NSRange.self))
  }

  public static func _forceBridgeFromObjectiveC(_ source: NSValue,
                                                result: inout NSRange?) {
    precondition(strcmp(source.objCType(),
                        _getObjCTypeEncoding(NSRange.self)) == 0,
                 "NSValue does not contain the right type to bridge to NSRange")
    result = NSRange()
    source.getValue(&result!)
  }

  public static func _conditionallyBridgeFromObjectiveC(_ source: NSValue,
                                                        result: inout NSRange?)
      -> Bool {
    if strcmp(source.objCType(), _getObjCTypeEncoding(NSRange.self)) != 0 {
      result = nil
      return false
    }
    result = NSRange()
    source.getValue(&result!)
    return true
  }

  public static func _unconditionallyBridgeFromObjectiveC(_ source: NSValue?)
      -> NSRange {
    let unwrappedSource = source!
    precondition(strcmp(unwrappedSource.objCType(),
                        _getObjCTypeEncoding(NSRange.self)) == 0,
                 "NSValue does not contain the right type to bridge to NSRange")
    var result = NSRange()
    unwrappedSource.getValue(&result)
    return result
  }
}


extension CGRect: _ObjectiveCBridgeable {
  public func _bridgeToObjectiveC() -> NSValue {
    var myself = self
    return NSValue(bytes: &myself, objCType: _getObjCTypeEncoding(CGRect.self))
  }

  public static func _forceBridgeFromObjectiveC(_ source: NSValue,
                                                result: inout CGRect?) {
    precondition(strcmp(source.objCType(),
                        _getObjCTypeEncoding(CGRect.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGRect")
    result = CGRect()
    source.getValue(&result!)
  }

  public static func _conditionallyBridgeFromObjectiveC(_ source: NSValue,
                                                        result: inout CGRect?)
      -> Bool {
    if strcmp(source.objCType(), _getObjCTypeEncoding(CGRect.self)) != 0 {
      result = nil
      return false
    }
    result = CGRect()
    source.getValue(&result!)
    return true
  }

  public static func _unconditionallyBridgeFromObjectiveC(_ source: NSValue?)
      -> CGRect {
    let unwrappedSource = source!
    precondition(strcmp(unwrappedSource.objCType(),
                        _getObjCTypeEncoding(CGRect.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGRect")
    var result = CGRect()
    unwrappedSource.getValue(&result)
    return result
  }
}


extension CGPoint: _ObjectiveCBridgeable {
  public func _bridgeToObjectiveC() -> NSValue {
    var myself = self
    return NSValue(bytes: &myself, objCType: _getObjCTypeEncoding(CGPoint.self))
  }

  public static func _forceBridgeFromObjectiveC(_ source: NSValue,
                                                result: inout CGPoint?) {
    precondition(strcmp(source.objCType(),
                        _getObjCTypeEncoding(CGPoint.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGPoint")
    result = CGPoint()
    source.getValue(&result!)
  }

  public static func _conditionallyBridgeFromObjectiveC(_ source: NSValue,
                                                        result: inout CGPoint?)
      -> Bool {
    if strcmp(source.objCType(), _getObjCTypeEncoding(CGPoint.self)) != 0 {
      result = nil
      return false
    }
    result = CGPoint()
    source.getValue(&result!)
    return true
  }

  public static func _unconditionallyBridgeFromObjectiveC(_ source: NSValue?)
      -> CGPoint {
    let unwrappedSource = source!
    precondition(strcmp(unwrappedSource.objCType(),
                        _getObjCTypeEncoding(CGPoint.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGPoint")
    var result = CGPoint()
    unwrappedSource.getValue(&result)
    return result
  }
}


extension CGVector: _ObjectiveCBridgeable {
  public func _bridgeToObjectiveC() -> NSValue {
    var myself = self
    return NSValue(bytes: &myself, objCType: _getObjCTypeEncoding(CGVector.self))
  }

  public static func _forceBridgeFromObjectiveC(_ source: NSValue,
                                                result: inout CGVector?) {
    precondition(strcmp(source.objCType(),
                        _getObjCTypeEncoding(CGVector.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGVector")
    result = CGVector()
    source.getValue(&result!)
  }

  public static func _conditionallyBridgeFromObjectiveC(_ source: NSValue,
                                                        result: inout CGVector?)
      -> Bool {
    if strcmp(source.objCType(), _getObjCTypeEncoding(CGVector.self)) != 0 {
      result = nil
      return false
    }
    result = CGVector()
    source.getValue(&result!)
    return true
  }

  public static func _unconditionallyBridgeFromObjectiveC(_ source: NSValue?)
      -> CGVector {
    let unwrappedSource = source!
    precondition(strcmp(unwrappedSource.objCType(),
                        _getObjCTypeEncoding(CGVector.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGVector")
    var result = CGVector()
    unwrappedSource.getValue(&result)
    return result
  }
}


extension CGSize: _ObjectiveCBridgeable {
  public func _bridgeToObjectiveC() -> NSValue {
    var myself = self
    return NSValue(bytes: &myself, objCType: _getObjCTypeEncoding(CGSize.self))
  }

  public static func _forceBridgeFromObjectiveC(_ source: NSValue,
                                                result: inout CGSize?) {
    precondition(strcmp(source.objCType(),
                        _getObjCTypeEncoding(CGSize.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGSize")
    result = CGSize()
    source.getValue(&result!)
  }

  public static func _conditionallyBridgeFromObjectiveC(_ source: NSValue,
                                                        result: inout CGSize?)
      -> Bool {
    if strcmp(source.objCType(), _getObjCTypeEncoding(CGSize.self)) != 0 {
      result = nil
      return false
    }
    result = CGSize()
    source.getValue(&result!)
    return true
  }

  public static func _unconditionallyBridgeFromObjectiveC(_ source: NSValue?)
      -> CGSize {
    let unwrappedSource = source!
    precondition(strcmp(unwrappedSource.objCType(),
                        _getObjCTypeEncoding(CGSize.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGSize")
    var result = CGSize()
    unwrappedSource.getValue(&result)
    return result
  }
}


extension CGAffineTransform: _ObjectiveCBridgeable {
  public func _bridgeToObjectiveC() -> NSValue {
    var myself = self
    return NSValue(bytes: &myself, objCType: _getObjCTypeEncoding(CGAffineTransform.self))
  }

  public static func _forceBridgeFromObjectiveC(_ source: NSValue,
                                                result: inout CGAffineTransform?) {
    precondition(strcmp(source.objCType(),
                        _getObjCTypeEncoding(CGAffineTransform.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGAffineTransform")
    result = CGAffineTransform()
    source.getValue(&result!)
  }

  public static func _conditionallyBridgeFromObjectiveC(_ source: NSValue,
                                                        result: inout CGAffineTransform?)
      -> Bool {
    if strcmp(source.objCType(), _getObjCTypeEncoding(CGAffineTransform.self)) != 0 {
      result = nil
      return false
    }
    result = CGAffineTransform()
    source.getValue(&result!)
    return true
  }

  public static func _unconditionallyBridgeFromObjectiveC(_ source: NSValue?)
      -> CGAffineTransform {
    let unwrappedSource = source!
    precondition(strcmp(unwrappedSource.objCType(),
                        _getObjCTypeEncoding(CGAffineTransform.self)) == 0,
                 "NSValue does not contain the right type to bridge to CGAffineTransform")
    var result = CGAffineTransform()
    unwrappedSource.getValue(&result)
    return result
  }
}


extension NSValue {
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func value<StoredType>(of type: StoredType.Type) -> StoredType? {
        if StoredType.self is AnyObject.Type {
            let encoding = String(cString: objCType())
            // some subclasses of NSValue can return @ and the default initialized variant returns ^v for encoding
            guard encoding == "^v" || encoding == "@" else {
                return nil
            }
            return nonretainedObjectValue as? StoredType
        } else if _isPOD(StoredType.self) {
            var storedSize = 0
            var storedAlignment = 0
            NSGetSizeAndAlignment(objCType(), &storedSize, &storedAlignment)
            guard MemoryLayout<StoredType>.size == storedSize && MemoryLayout<StoredType>.alignment == storedAlignment else {
                return nil
            }
            let allocated = UnsafeMutablePointer<StoredType>.allocate(capacity: 1)
            defer { allocated.deallocate() }
            getValue(allocated)
            return allocated.pointee
        }
        return nil
    }
}
