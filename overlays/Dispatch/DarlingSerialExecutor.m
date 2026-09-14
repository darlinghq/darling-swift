// DARLING: macOS 14 adds the dispatch_queue_serial_executor class, which the Swift overlay extends with
// SerialExecutor. Darling's libdispatch doesn't have it yet, so define it here so binaries that import
// the extension's symbols can load. Apple's hierarchy makes dispatch_queue_serial a subclass of it;
// here it is only a subclass of OS_dispatch_queue.
//
// This file deliberately doesn't include the dispatch headers: in Objective-C they declare the
// OS_dispatch_* types as protocols, so the superclass is declared directly (libdispatch defines it).
#import <objc/NSObject.h>

@interface OS_dispatch_queue : NSObject
@end

__attribute__((visibility("default")))
@interface OS_dispatch_queue_serial_executor : OS_dispatch_queue
@end

@implementation OS_dispatch_queue_serial_executor
@end
