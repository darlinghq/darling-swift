// Declarations the CoreGraphics Swift overlay needs, written for Darling from the CoreGraphics API documentation.
// Darling's CoreGraphics headers include Foundation and have no Clang module, so the overlay can't import them; this
// declares CGContext as the CF type apps' mangled names use (`So12CGContextRefa`). The functions are exported by
// Darling's CoreGraphics.framework.
#ifndef DARLING_COREGRAPHICS_SHIMS_H
#define DARLING_COREGRAPHICS_SHIMS_H

#include <CoreGraphics/CGGeometry.h>

typedef struct CF_BRIDGED_TYPE(id) CGContext *CGContextRef;

void CGContextAddLineToPoint(CGContextRef context, CGFloat x, CGFloat y);
void CGContextAddArc(CGContextRef context, CGFloat x, CGFloat y, CGFloat radius, CGFloat startAngle, CGFloat endAngle,
                     bool clockwise);

#endif
