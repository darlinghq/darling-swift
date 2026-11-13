// Darling CoreGraphics functions tests/appkit_coregraphics.swift uses to build a context and inspect its path, declared
// with the CGContextRef of the CoreGraphics overlay's shim module (Darling's CGContext.h spells it differently).
@import _DarlingCoreGraphicsShims;

typedef struct CF_BRIDGED_TYPE(id) CGColorSpace *CGColorSpaceRef;

CF_IMPLICIT_BRIDGING_ENABLED
CGColorSpaceRef CGColorSpaceCreateDeviceRGB(void);
CGContextRef CGBitmapContextCreate(void *data, size_t width, size_t height, size_t bitsPerComponent, size_t bytesPerRow,
                                   CGColorSpaceRef colorSpace, uint32_t bitmapInfo);
CF_IMPLICIT_BRIDGING_DISABLED

void CGContextBeginPath(CGContextRef context);
void CGContextMoveToPoint(CGContextRef context, CGFloat x, CGFloat y);
CGPoint CGContextGetPathCurrentPoint(CGContextRef context);
CGRect CGContextGetPathBoundingBox(CGContextRef context);
