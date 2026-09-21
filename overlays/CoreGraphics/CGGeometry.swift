//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// The CGPoint, CGSize and CGRect members below come from swift-corelibs-foundation
// (release/5.4, Sources/Foundation/NSGeometry.swift), where they are written in Swift because
// Linux has no CoreGraphics to import them from. On macOS the same members reach Swift as
// Clang-importer renames of the C functions, driven by the SDK's CoreGraphics.apinotes
// (CGRectGetMinX becomes getter:CGRect.minX(self:), and so on); Darling's SDK ships no such file,
// and the Swift CoreGraphics overlay in swiftlang/swift never declared them. Darling's CGRect,
// CGPoint and CGSize are the C structs, so the extensions below apply to them unchanged.
//
// Upstream is taken as-is. Where Darling's C CoreGraphics disagrees with it, see DARLING-CHANGES.md.

import _DarlingCoreGraphicsShims

extension CGPoint {
    public static var zero: CGPoint {
        return CGPoint(x: CGFloat(0), y: CGFloat(0))
    }
    
    public init(x: Int, y: Int) {
        self.init(x: CGFloat(x), y: CGFloat(y))
    }
    
    public init(x: Double, y: Double) {
        self.init(x: CGFloat(x), y: CGFloat(y))
    }
}

extension CGPoint: Equatable {
    public static func ==(lhs: CGPoint, rhs: CGPoint) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

extension CGSize {
    public static var zero: CGSize {
        return CGSize(width: 0, height: 0)
    }
    
    public init(width: Int, height: Int) {
        self.init(width: CGFloat(width), height: CGFloat(height))
    }
    
    public init(width: Double, height: Double) {
        self.init(width: CGFloat(width), height: CGFloat(height))
    }
}

extension CGSize: Equatable {
    public static func ==(lhs: CGSize, rhs: CGSize) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height
    }
}

extension CGRect {
    public static var zero: CGRect {
        return CGRect(origin: CGPoint(), size: CGSize())
    }
    
    public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.init(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))
    }
    
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.init(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))
    }
    
    public init(x: Int, y: Int, width: Int, height: Int) {
        self.init(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))
    }
}

extension CGRect {
    public static let null = CGRect(x: CGFloat.infinity,
                                    y: CGFloat.infinity,
                                    width: CGFloat(0),
                                    height: CGFloat(0))
    
    public static let infinite = CGRect(x: -CGFloat.greatestFiniteMagnitude / 2,
                                        y: -CGFloat.greatestFiniteMagnitude / 2,
                                        width: CGFloat.greatestFiniteMagnitude,
                                        height: CGFloat.greatestFiniteMagnitude)

    public var width: CGFloat { return abs(self.size.width) }
    public var height: CGFloat { return abs(self.size.height) }

    public var minX: CGFloat { return self.origin.x + min(self.size.width, 0) }
    public var midX: CGFloat { return (self.minX + self.maxX) * 0.5 }
    public var maxX: CGFloat { return self.origin.x + max(self.size.width, 0) }

    public var minY: CGFloat { return self.origin.y + min(self.size.height, 0) }
    public var midY: CGFloat { return (self.minY + self.maxY) * 0.5 }
    public var maxY: CGFloat { return self.origin.y + max(self.size.height, 0) }

    public var isEmpty: Bool { return self.isNull || self.size.width == 0 || self.size.height == 0 }
    public var isInfinite: Bool { return self == .infinite }
    public var isNull: Bool { return self.origin.x == .infinity || self.origin.y == .infinity }

    public func contains(_ point: CGPoint) -> Bool {
        if self.isNull || self.isEmpty { return false }

        return (self.minX..<self.maxX).contains(point.x) && (self.minY..<self.maxY).contains(point.y)
    }

    public func contains(_ rect2: CGRect) -> Bool {
        return self.union(rect2) == self
    }

    public var standardized: CGRect {
        if self.isNull { return .null }

        return CGRect(x: self.minX,
                      y: self.minY,
                      width: self.width,
                      height: self.height)
    }

    public var integral: CGRect {
        if self.isNull { return self }

        let standardized = self.standardized
        let x = standardized.origin.x.rounded(.down)
        let y = standardized.origin.y.rounded(.down)
        let width = (standardized.origin.x + standardized.size.width).rounded(.up) - x
        let height = (standardized.origin.y + standardized.size.height).rounded(.up) - y
        return CGRect(x: x, y: y, width: width, height: height)
    }

    public func insetBy(dx: CGFloat, dy: CGFloat) -> CGRect {
        if self.isNull { return self }

        var rect = self.standardized

        rect.origin.x += dx
        rect.origin.y += dy
        rect.size.width -= 2 * dx
        rect.size.height -= 2 * dy

        if rect.size.width < 0 || rect.size.height < 0 {
            return .null
        }

        return rect
    }

    public func union(_ r2: CGRect) -> CGRect {
        if self.isNull {
            return r2
        }
        else if r2.isNull {
            return self
        }

        let rect1 = self.standardized
        let rect2 = r2.standardized

        let minX = min(rect1.minX, rect2.minX)
        let minY = min(rect1.minY, rect2.minY)
        let maxX = max(rect1.maxX, rect2.maxX)
        let maxY = max(rect1.maxY, rect2.maxY)

        return CGRect(x: minX,
                      y: minY,
                      width: maxX - minX,
                      height: maxY - minY)
    }

    public func intersection(_ r2: CGRect) -> CGRect {
        if self.isNull || r2.isNull { return .null }

        let rect1 = self.standardized
        let rect2 = r2.standardized

        let rect1SpanH = rect1.minX...rect1.maxX
        let rect1SpanV = rect1.minY...rect1.maxY

        let rect2SpanH = rect2.minX...rect2.maxX
        let rect2SpanV = rect2.minY...rect2.maxY

        if !rect1SpanH.overlaps(rect2SpanH) || !rect1SpanV.overlaps(rect2SpanV) {
            return .null
        }

        let overlapH = rect1SpanH.clamped(to: rect2SpanH)
        let overlapV = rect1SpanV.clamped(to: rect2SpanV)

        let width: CGFloat
        if overlapH == rect1SpanH {
            width = rect1.width
        } else if overlapH == rect2SpanH {
            width = rect2.width
        } else {
            width = overlapH.upperBound - overlapH.lowerBound
        }

        let height: CGFloat
        if overlapV == rect1SpanV {
            height = rect1.height
        } else if overlapV == rect2SpanV {
            height = rect2.height
        } else {
            height = overlapV.upperBound - overlapV.lowerBound
        }

        return CGRect(x: overlapH.lowerBound,
                      y: overlapV.lowerBound,
                      width: width,
                      height: height)
    }

    public func intersects(_ r2: CGRect) -> Bool {
        return !self.intersection(r2).isNull
    }

    public func offsetBy(dx: CGFloat, dy: CGFloat) -> CGRect {
        if self.isNull { return self }

        var rect = self.standardized
        rect.origin.x += dx
        rect.origin.y += dy
        return rect
    }

    public func divided(atDistance: CGFloat, from fromEdge: CGRectEdge) -> (slice: CGRect, remainder: CGRect) {
        if self.isNull { return (.null, .null) }

        let splitLocation: CGFloat
        switch fromEdge {
        case .minXEdge: splitLocation = min(max(atDistance, 0), self.width)
        case .maxXEdge: splitLocation = min(max(self.width - atDistance, 0), self.width)
        case .minYEdge: splitLocation = min(max(atDistance, 0), self.height)
        case .maxYEdge: splitLocation = min(max(self.height - atDistance, 0), self.height)
        }

        let rect = self.standardized
        var rect1 = rect
        var rect2 = rect

        switch fromEdge {
        case .minXEdge: fallthrough
        case .maxXEdge:
            rect1.size.width = splitLocation
            rect2.origin.x = rect1.maxX
            rect2.size.width = rect.width - splitLocation
        case .minYEdge: fallthrough
        case .maxYEdge:
            rect1.size.height = splitLocation
            rect2.origin.y = rect1.maxY
            rect2.size.height = rect.height - splitLocation
        }

        switch fromEdge {
        case .minXEdge: fallthrough
        case .minYEdge: return (rect1, rect2)
        case .maxXEdge: fallthrough
        case .maxYEdge: return (rect2, rect1)
        }
    }
}

extension CGRect: Equatable {
    public static func ==(lhs: CGRect, rhs: CGRect) -> Bool {
        if lhs.isNull && rhs.isNull { return true }

        let r1 = lhs.standardized
        let r2 = rhs.standardized
        return r1.origin == r2.origin && r1.size == r2.size
    }
}
