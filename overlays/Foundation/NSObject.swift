//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2017 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@_exported import Foundation // Clang module
import ObjectiveC

// Key-value observing, from release/5.4 stdlib/public/Darwin/Foundation/NSObject.swift.
// Darling: the __KVOKeyPathBridgeMachinery swizzle of +automaticallyNotifiesObserversForKey: and
// +keyPathsForValuesAffectingValueForKey: (only used by NSKeyValueObservingCustomization) is omitted, change
// dictionary keys are Darling's NSKeyValueChange*Key constants, and NS_OPTIONS import as raw-value structs.

// This exists to allow for dynamic dispatch on KVO methods added to NSObject.
// Extending NSObject with these methods would disallow overrides.
public protocol _KeyValueCodingAndObserving {}
extension NSObject : _KeyValueCodingAndObserving {}

// From release/5.4 Foundation.swift.
extension NSObject : CustomStringConvertible {}

public struct NSKeyValueObservedChange<Value> {
    public typealias Kind = NSKeyValueChange
    public let kind: Kind
    ///newValue and oldValue will only be non-nil if .new/.old is passed to `observe()`. In general, get the most up to date value by accessing it directly on the observed object instead.
    public let newValue: Value?
    public let oldValue: Value?
    ///indexes will be nil unless the observed KeyPath refers to an ordered to-many property
    public let indexes: IndexSet?
    ///'isPrior' will be true if this change observation is being sent before the change happens, due to .prior being passed to `observe()`
    public let isPrior:Bool
}

///Conforming to NSKeyValueObservingCustomization is not required to use Key-Value Observing. Provide an implementation of these functions if you need to disable auto-notifying for a key, or add dependent keys
public protocol NSKeyValueObservingCustomization : NSObjectProtocol {
    static func keyPathsAffectingValue(for key: AnyKeyPath) -> Set<AnyKeyPath>
    static func automaticallyNotifiesObservers(for key: AnyKeyPath) -> Bool
}

func _bridgeKeyPathToString(_ keyPath:AnyKeyPath) -> String {
    guard let keyPathString = keyPath._kvcKeyPathString else { fatalError("Could not extract a String from KeyPath \(keyPath)") }
    return keyPathString
}

// NOTE: older overlays called this NSKeyValueObservation. We now use
// that name in the source code, but add an underscore to the runtime
// name to avoid conflicts when both are loaded into the same process.
@objc(_NSKeyValueObservation)
public class NSKeyValueObservation : NSObject {
    // We use a private helper class as the actual observer. This lets us attach the helper as an associated object
    // to the object we're observing, thus ensuring the helper will still be alive whenever a KVO change notification
    // is broadcast, even on a background thread.
    //
    // For the associated object, we use the Helper instance itself as its own key. This guarantees key uniqueness.
    private class Helper : NSObject {
        @nonobjc weak var object : NSObject?
        @nonobjc let path: String
        @nonobjc let callback : (NSObject, NSKeyValueObservedChange<Any>) -> Void
        
        // workaround for <rdar://problem/31640524> Erroneous (?) error when using bridging in the Foundation overlay
        // specifically, overriding observeValue(forKeyPath:of:change:context:) complains that it's not Obj-C-compatible
        @nonobjc static let swizzler: () = {
            let bridgeClass: AnyClass = Helper.self
            let observeSel = #selector(NSObject.observeValue(forKeyPath:of:change:context:))
            let swapSel = #selector(Helper._swizzle_me_observeValue(forKeyPath:of:change:context:))
            let swapObserveMethod = class_getInstanceMethod(bridgeClass, swapSel)!
            class_addMethod(bridgeClass, observeSel, method_getImplementation(swapObserveMethod), method_getTypeEncoding(swapObserveMethod))
        }()
        
        @nonobjc init(object: NSObject, keyPath: AnyKeyPath, options: NSKeyValueObservingOptions, callback: @escaping (NSObject, NSKeyValueObservedChange<Any>) -> Void) {
            _ = Helper.swizzler
            let path = _bridgeKeyPathToString(keyPath)
            self.object = object
            self.path = path
            self.callback = callback
            super.init()
            objc_setAssociatedObject(object, associationKey(), self, .OBJC_ASSOCIATION_RETAIN)
            object.addObserver(self, forKeyPath: path, options: options, context: nil)
        }
        
        @nonobjc func invalidate() {
            guard let object = self.object else { return }
            object.removeObserver(self, forKeyPath: path, context: nil)
            objc_setAssociatedObject(object, associationKey(), nil, .OBJC_ASSOCIATION_ASSIGN)
            self.object = nil
        }
        
        @nonobjc private func associationKey() -> UnsafeRawPointer {
            return UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        }
        
        @objc private func _swizzle_me_observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSString : Any]?, context: UnsafeMutableRawPointer?) {
            guard let object = object as? NSObject, object === self.object, let change = change else { return }
            let rawKind = UInt(bitPattern: (change[NSKeyValueChangeKindKey as NSString] as? NSNumber)?.integerValue() ?? 1)
            let kind = NSKeyValueChange(rawValue: rawKind)
            // NSNull values are passed through: observe()'s converter turns them into .some(nil) for optional values.
            let notification = NSKeyValueObservedChange(kind: kind,
                                                        newValue: change[NSKeyValueChangeNewKey as NSString],
                                                        oldValue: change[NSKeyValueChangeOldKey as NSString],
                                                        indexes: (change[NSKeyValueChangeIndexesKey as NSString] as? NSIndexSet).map { IndexSet._unconditionallyBridgeFromObjectiveC($0) },
                                                        isPrior: (change[NSKeyValueChangeNotificationIsPriorKey as NSString] as? NSNumber)?.boolValue() ?? false)
            callback(object, notification)
        }
    }
    
    @nonobjc private let helper: Helper
    
    fileprivate init(object: NSObject, keyPath: AnyKeyPath, options: NSKeyValueObservingOptions, callback: @escaping (NSObject, NSKeyValueObservedChange<Any>) -> Void) {
        helper = Helper(object: object, keyPath: keyPath, options: options, callback: callback)
    }
    
    ///invalidate() will be called automatically when an NSKeyValueObservation is deinited
    @objc public func invalidate() {
        helper.invalidate()
    }
    
    deinit {
        invalidate()
    }
}

// Used for type-erase Optional type
private protocol _OptionalForKVO {
    static func _castForKVO(_ value: Any) -> Any?
}

extension Optional: _OptionalForKVO {
    static func _castForKVO(_ value: Any) -> Any? {
        return value as? Wrapped
    }
}

extension _KeyValueCodingAndObserving {
    
    ///when the returned NSKeyValueObservation is deinited or invalidated, it will stop observing
    public func observe<Value>(
            _ keyPath: KeyPath<Self, Value>,
            options: NSKeyValueObservingOptions = NSKeyValueObservingOptions(rawValue: 0),
            changeHandler: @escaping (Self, NSKeyValueObservedChange<Value>) -> Void)
        -> NSKeyValueObservation {
        return NSKeyValueObservation(object: self as! NSObject, keyPath: keyPath, options: options) { (obj, change) in
            
            let converter = { (changeValue: Any?) -> Value? in
                if let optionalType = Value.self as? _OptionalForKVO.Type {
                    // Special logic for keyPath having a optional target value. When the keyPath referencing a nil value, the newValue/oldValue should be in the form .some(nil) instead of .none
                    // Solve https://bugs.swift.org/browse/SR-6066
                    
                    // NSNull is used by KVO to signal that the keyPath value is nil.
                    // If Value == Optional<T>.self, We will get nil instead of .some(nil) when casting Optional(<null>) directly.
                    // To fix this behavior, we will eliminate NSNull first, then cast the transformed value.
                    
                    if let unwrapped = changeValue {
                        // We use _castForKVO to cast first.
                        // If Value != Optional<NSNull>.self, the NSNull value will be eliminated.
                        let nullEliminatedValue = optionalType._castForKVO(unwrapped) as Any
                        let transformedOptional: Any? = nullEliminatedValue
                        return transformedOptional as? Value
                    }
                }
                return changeValue as? Value
            }
            
            let notification = NSKeyValueObservedChange(kind: change.kind,
                                                        newValue: converter(change.newValue),
                                                        oldValue: converter(change.oldValue),
                                                        indexes: change.indexes,
                                                        isPrior: change.isPrior)
            changeHandler(obj as! Self, notification)
        }
    }
    
    public func willChangeValue<Value>(for keyPath: __owned KeyPath<Self, Value>) {
        (self as! NSObject).willChangeValue(forKey: _bridgeKeyPathToString(keyPath))
    }
    
    public func willChange<Value>(_ changeKind: NSKeyValueChange, valuesAt indexes: IndexSet, for keyPath: __owned KeyPath<Self, Value>) {
        (self as! NSObject).willChange(changeKind, valuesAt: indexes._bridgeToObjectiveC(), forKey: _bridgeKeyPathToString(keyPath))
    }
    
    public func willChangeValue<Value>(for keyPath: __owned KeyPath<Self, Value>, withSetMutation mutation: NSKeyValueSetMutationKind, using set: Set<Value>) -> Void {
        (self as! NSObject).willChangeValue(forKey: _bridgeKeyPathToString(keyPath), withSetMutation: mutation, using: Set(set.map { AnyHashable($0) }))
    }

    public func didChangeValue<Value>(for keyPath: __owned KeyPath<Self, Value>) {
        (self as! NSObject).didChangeValue(forKey: _bridgeKeyPathToString(keyPath))
    }
    
    public func didChange<Value>(_ changeKind: NSKeyValueChange, valuesAt indexes: IndexSet, for keyPath: __owned KeyPath<Self, Value>) {
        (self as! NSObject).didChange(changeKind, valuesAt: indexes._bridgeToObjectiveC(), forKey: _bridgeKeyPathToString(keyPath))
    }
    
    public func didChangeValue<Value>(for keyPath: __owned KeyPath<Self, Value>, withSetMutation mutation: NSKeyValueSetMutationKind, using set: Set<Value>) -> Void {
        (self as! NSObject).didChangeValue(forKey: _bridgeKeyPathToString(keyPath), withSetMutation: mutation, using: Set(set.map { AnyHashable($0) }))
    }
}
