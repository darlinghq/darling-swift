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

// `CGAffineTransform.identity`, the `Equatable` conformance and the `Codable` conformance below are
// swiftlang/swift release/5.4, stdlib/public/Darwin/CoreGraphics/CoreGraphics.swift. Upstream calls
// `__equalTo`, which is what the SDK's CoreGraphics.apinotes renames CGAffineTransformEqualToTransform
// to; Darling's SDK ships no apinotes, so the C function is called under its own name.
//
// The remaining members are Clang-importer renames on macOS, also driven by that apinotes file
// (CGAffineTransformInvert becomes CGAffineTransform.inverted(), CGAffineTransformMakeTranslation
// becomes CGAffineTransform.init(translationX:y:), and so on). There is no Swift source for them
// anywhere in swiftlang/swift. They are written here over the same C functions, which Darling's
// CGAffineTransform.h declares and CoreGraphics.framework exports.

import _DarlingCoreGraphicsShims

extension CGAffineTransform: Equatable {
  public static func ==(lhs: CGAffineTransform,
                        rhs: CGAffineTransform) -> Bool {
    return CGAffineTransformEqualToTransform(lhs, rhs)
  }
}

extension CGAffineTransform {
  public static var identity: CGAffineTransform {
    @_transparent // @fragile
    get { return CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0) }
  }
}

extension CGAffineTransform: Codable {
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    let a = try container.decode(CGFloat.self)
    let b = try container.decode(CGFloat.self)
    let c = try container.decode(CGFloat.self)
    let d = try container.decode(CGFloat.self)
    let tx = try container.decode(CGFloat.self)
    let ty = try container.decode(CGFloat.self)
    self.init(a: a, b: b, c: c, d: d, tx: tx, ty: ty)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(a)
    try container.encode(b)
    try container.encode(c)
    try container.encode(d)
    try container.encode(tx)
    try container.encode(ty)
  }
}

extension CGAffineTransform {
  public init(translationX tx: CGFloat, y ty: CGFloat) {
    self = CGAffineTransformMakeTranslation(tx, ty)
  }

  public init(scaleX sx: CGFloat, y sy: CGFloat) {
    self = CGAffineTransformMakeScale(sx, sy)
  }

  public init(rotationAngle angle: CGFloat) {
    self = CGAffineTransformMakeRotation(angle)
  }

  public var isIdentity: Bool {
    return CGAffineTransformIsIdentity(self)
  }

  public func inverted() -> CGAffineTransform {
    return CGAffineTransformInvert(self)
  }

  public func concatenating(_ t2: CGAffineTransform) -> CGAffineTransform {
    return CGAffineTransformConcat(self, t2)
  }

  public func translatedBy(x tx: CGFloat, y ty: CGFloat) -> CGAffineTransform {
    return CGAffineTransformTranslate(self, tx, ty)
  }

  public func scaledBy(x sx: CGFloat, y sy: CGFloat) -> CGAffineTransform {
    return CGAffineTransformScale(self, sx, sy)
  }

  public func rotated(by angle: CGFloat) -> CGAffineTransform {
    return CGAffineTransformRotate(self, angle)
  }
}
