// Swift-only generic overlay for the NS_REFINED_FOR_SWIFT entry points declared in
// darling-foundation's NSKeyedArchiver.h, matching the public API shape of
// swift-corelibs-foundation's NSKeyedUnarchiver.swift (Apache License 2.0).

extension NSKeyedUnarchiver {
    @nonobjc
    public class func unarchivedObject<DecodedObjectType>(
        ofClass cls: DecodedObjectType.Type,
        from data: Data
    ) throws -> DecodedObjectType? where DecodedObjectType: NSObject, DecodedObjectType: NSCoding {
        let object = try __unarchivedObject(ofClass: cls, fromData: data)
        return object as? DecodedObjectType
    }

    @nonobjc
    public class func unarchivedObject(
        ofClasses classes: [AnyClass],
        from data: Data
    ) throws -> Any? {
        // The refined ObjC entry point takes NSSet<Class> *, which the importer bridges to
        // Set<AnyHashable>; go through NSSet directly since AnyClass isn't Hashable in Swift.
        try __unarchivedObject(ofClasses: NSSet(array: classes) as! Set<AnyHashable>, fromData: data)
    }
}
