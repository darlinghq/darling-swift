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
