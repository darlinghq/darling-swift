//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// From release/5.4 stdlib/public/Darwin/Foundation/NSCoder.swift, reduced to decodeObject(of:forKey:). Darling has no
// _SwiftFoundationOverlayShims, so the methods call -decodeObjectOfClass:forKey: and -decodeObjectOfClasses:forKey:
// directly.

@_exported import Foundation // Clang module

extension NSCoder {
  public func decodeObject<DecodedObjectType>(
    of cls: DecodedObjectType.Type, forKey key: String
  ) -> DecodedObjectType?
    where DecodedObjectType : NSCoding, DecodedObjectType : NSObject {
    let result: Any? = decodeObject(of: cls as AnyClass, forKey: key)
    return result as? DecodedObjectType
  }

  @nonobjc
  public func decodeObject(of classes: [AnyClass]?, forKey key: String) -> Any? {
    var classesAsNSObjects: NSSet?
    if let theClasses = classes {
      classesAsNSObjects = NSSet(array: theClasses.map { $0 as AnyObject })
    }
    // Darling imports the NSSet parameter as Set<AnyHashable>, which can't hold class objects, so call the
    // implementation with the Objective-C types.
    typealias DecodeObjectOfClasses = @convention(c) (NSCoder, Selector, NSSet?, NSString) -> AnyObject?
    let selector = Selector(("decodeObjectOfClasses:forKey:"))
    let decode = unsafeBitCast(method(for: selector), to: DecodeObjectOfClasses.self)
    return decode(self, selector, classesAsNSObjects, key as NSString)
  }
}
