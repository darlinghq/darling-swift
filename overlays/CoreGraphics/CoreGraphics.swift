// Darling's CoreGraphics (Cocotron) has no Clang module of its own: its C types and CGFloat come through
// CoreFoundation and Foundation. This module exists so the Clang importer can map C `CGFloat` to
// `CoreGraphics.CGFloat` (defined in the CoreFoundation overlay), and so arm64 binaries that autolink
// libswiftCoreGraphics find a slice.
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
