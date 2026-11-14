// Darling AppKit methods tests/appkit_popupbutton.swift calls, which the AppKit overlay's shim does not declare.
#import <Foundation/Foundation.h>
@import _DarlingAppKitShims;

@interface NSMenu (DarlingTest)
- (nonnull instancetype)initWithTitle:(NSString *)title;
- (nullable id)addItemWithTitle:(NSString *)title action:(nullable SEL)selector keyEquivalent:(NSString *)charCode;
@property (readonly) NSInteger numberOfItems;
- (nullable id)itemAtIndex:(NSInteger)index;
@end

@interface NSImage (DarlingTest)
- (nonnull instancetype)initWithSize:(NSSize)size;
@end

@interface NSPopUpButton (DarlingTest)
@property (readonly, copy, nullable) NSString *titleOfSelectedItem;
@end
