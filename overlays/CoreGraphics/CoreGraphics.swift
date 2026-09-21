// Darling's CoreGraphics (Cocotron) has no Clang module of its own: its C types and CGFloat come through
// CoreFoundation and Foundation. This module exists so the Clang importer can map C `CGFloat` to
// `CoreGraphics.CGFloat` (defined in the CoreFoundation overlay), and so arm64 binaries that autolink
// libswiftCoreGraphics find a slice.
// Re-export the CoreGraphics Clang module. Without this, a Swift module named CoreGraphics
// shadows the Clang module of the same name and every C type behind it becomes unreachable from
// Swift, even though Darling's headers declare them all.
@_exported import CoreGraphics
@_exported import CoreFoundation
import _DarlingCoreGraphicsShims

// The CGContext methods below are from release/5.2 stdlib/public/Darwin/CoreGraphics/CoreGraphics.swift
// (Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors, Apache License v2.0 with Runtime Library
// Exception), calling the C functions directly because Darling's headers have no Swift names for them.
extension CGContext {
  public func addLine(to point: CGPoint) {
    CGContextAddLineToPoint(self, point.x, point.y)
  }

  public func addArc(center: CGPoint, radius: CGFloat, startAngle: CGFloat,
   endAngle: CGFloat, clockwise: Bool) {
    CGContextAddArc(self, center.x, center.y, radius, startAngle, endAngle, clockwise)
  }
}

// CGRect.applying, CGPoint.applying, CGSize.applying, CGImage.width and CGImage.height are
// Clang-importer renames of C functions on macOS, driven by the SDK's CoreGraphics.apinotes
// (CGRectApplyAffineTransform becomes CGRect.applying(_:), CGImageGetWidth becomes
// getter:CGImage.width(self:)). Darling's SDK ships no such file, so they are written here over
// the same C functions, the way the CGContext methods above are. There is no Swift source for
// them in swiftlang/swift: the Darwin overlay never declared them either.
extension CGRect {
  public func applying(_ t: CGAffineTransform) -> CGRect {
    return CGRectApplyAffineTransform(self, t)
  }
}

extension CGPoint {
  public func applying(_ t: CGAffineTransform) -> CGPoint {
    return __CGPointApplyAffineTransform(self, t)
  }
}

extension CGSize {
  public func applying(_ t: CGAffineTransform) -> CGSize {
    return __CGSizeApplyAffineTransform(self, t)
  }
}

extension CGImage {
  public var width: Int { return CGImageGetWidth(self) }
  public var height: Int { return CGImageGetHeight(self) }
}

// Everything below is a Clang-importer rename on macOS, driven by the SDK's CoreGraphics.apinotes
// (CGImageGetColorSpace becomes getter:CGImage.colorSpace(self:), CGContextScaleCTM becomes
// CGContext.scaleBy(x:y:), kCGColorSpaceSRGB becomes CGColorSpace.sRGB, and so on). Darling's SDK
// ships no apinotes file, so each one is written here over the C function or constant that Darling's
// headers declare, the same way CGImage.width and CGRect.applying are written above. swiftlang/swift
// has no Swift source for any of them.

extension CGImage {
  public var colorSpace: CGColorSpace? { return CGImageGetColorSpace(self) }
}

extension CGContext {
  public var ctm: CGAffineTransform { return CGContextGetCTM(self) }

  public func scaleBy(x sx: CGFloat, y sy: CGFloat) {
    CGContextScaleCTM(self, sx, sy)
  }

  public func translateBy(x tx: CGFloat, y ty: CGFloat) {
    CGContextTranslateCTM(self, tx, ty)
  }

  public func rotate(by angle: CGFloat) {
    CGContextRotateCTM(self, angle)
  }

  public func concatenate(_ transform: CGAffineTransform) {
    CGContextConcatCTM(self, transform)
  }

  public func draw(_ image: CGImage, in rect: CGRect) {
    CGContextDrawImage(self, rect, image)
  }

  // CGBitmapContextCreateImage, which Apple's apinotes renames onto CGContext rather than onto a
  // bitmap-context type: CGBitmapContext is not a separate type in C. Darling's CGBitmapContext.h is
  // outside a CF_IMPLICIT_BRIDGING region, so the importer hands back an Unmanaged; the C function
  // follows the Create rule and returns +1, so the reference is taken retained.
  public func makeImage() -> CGImage? {
    return CGBitmapContextCreateImage(self)?.takeRetainedValue()
  }
}

extension CGColor {
  public var alpha: CGFloat { return CGColorGetAlpha(self) }

  public var colorSpace: CGColorSpace? { return CGColorGetColorSpace(self) }

  public var numberOfComponents: Int { return CGColorGetNumberOfComponents(self) }

  // Body from swiftlang/swift release/5.4, stdlib/public/Darwin/CoreGraphics/CoreGraphics.swift,
  // with __unsafeComponents (the apinotes name for CGColorGetComponents) spelled as the C function.
  public var components: [CGFloat]? {
    guard let pointer = CGColorGetComponents(self) else { return nil }
    let buffer = UnsafeBufferPointer(start: pointer, count: self.numberOfComponents)
    return Array(buffer)
  }

  public func copy(alpha: CGFloat) -> CGColor? {
    return CGColorCreateCopyWithAlpha(self, alpha)
  }
}

extension CGColorSpace {
  public static var sRGB: CFString { return kCGColorSpaceSRGB }
  public static var displayP3: CFString { return kCGColorSpaceDisplayP3 }
  public static var linearSRGB: CFString { return kCGColorSpaceLinearSRGB }
  public static var extendedSRGB: CFString { return kCGColorSpaceExtendedSRGB }
  public static var extendedLinearSRGB: CFString { return kCGColorSpaceExtendedLinearSRGB }
}

extension CGPath {
  public var isEmpty: Bool { return CGPathIsEmpty(self) }

  public var boundingBoxOfPath: CGRect { return CGPathGetPathBoundingBox(self) }

  public var boundingBox: CGRect { return CGPathGetBoundingBox(self) }

  public func copy() -> CGPath? { return CGPathCreateCopy(self) }

  public func mutableCopy() -> CGMutablePath? { return CGPathCreateMutableCopy(self) }
}
