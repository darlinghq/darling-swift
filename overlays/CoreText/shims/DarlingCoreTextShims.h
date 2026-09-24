// CTAdaptiveImageGlyph is private on macOS. The interface matches OpenSwiftUI's own declaration, since Clang rejects a
// class two modules define differently; the category holds Darling CoreText's content accessors.
#ifndef DARLING_CORETEXT_SHIMS_H
#define DARLING_CORETEXT_SHIMS_H

#import <CoreText/CoreText.h>
#import <Foundation/Foundation.h>

NS_HEADER_AUDIT_BEGIN(nullability, sendability)

NS_SWIFT_SENDABLE
@interface CTAdaptiveImageGlyph : NSObject <CTAdaptiveImageProviding>
@end

@interface CTAdaptiveImageGlyph (DarlingImageContent)
- (instancetype)initWithImageContent:(NSData *)imageContent;
@property (readonly) NSData *imageContent;
@end

NS_HEADER_AUDIT_END(nullability, sendability)

#endif
