//===--- tgmath.swift.gyb -------------------------------------*- swift -*-===//
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

import SwiftShims

// Generic functions implementable directly on FloatingPoint.
@_transparent
@available(swift, deprecated: 4.2/*, obsoleted: 5.1*/, renamed: "abs")
public func fabs<T: FloatingPoint>(_ x: T) -> T {
  return x.magnitude
}

@_transparent
public func sqrt<T: FloatingPoint>(_ x: T) -> T {
  return x.squareRoot()
}

@_transparent
public func fma<T: FloatingPoint>(_ x: T, _ y: T, _ z: T) -> T {
  return z.addingProduct(x, y)
}

@_transparent
public func remainder<T: FloatingPoint>(_ x: T, _ y: T) -> T {
  return x.remainder(dividingBy: y)
}

@_transparent
public func fmod<T: FloatingPoint>(_ x: T, _ y: T) -> T {
  return x.truncatingRemainder(dividingBy: y)
}

@_transparent
public func ceil<T: FloatingPoint>(_ x: T) -> T {
  return x.rounded(.up)
}

@_transparent
public func floor<T: FloatingPoint>(_ x: T) -> T {
  return x.rounded(.down)
}

@_transparent
public func round<T: FloatingPoint>(_ x: T) -> T {
  return x.rounded()
}

@_transparent
public func trunc<T: FloatingPoint>(_ x: T) -> T {
  return x.rounded(.towardZero)
}

@_transparent
public func scalbn<T: FloatingPoint>(_ x: T, _ n : Int) -> T {
  return T(sign: .plus, exponent: T.Exponent(n), significand: x)
}

@_transparent
public func modf<T: FloatingPoint>(_ x: T) -> (T, T) {
  // inf/NaN: return canonicalized x, fractional part zero.
  guard x.isFinite else { return (x+0, 0) }
  let integral = trunc(x)
  let fractional = x - integral
  return (integral, fractional)
}

@_transparent
public func frexp<T: BinaryFloatingPoint>(_ x: T) -> (T, Int) {
  guard x.isFinite else { return (x+0, 0) }
  guard x != 0 else { return (x, 0) }
  // The C stdlib `frexp` uses a different notion of significand / exponent
  // than IEEE 754, so we need to adjust them by a factor of two.
  return (x.significand / 2, Int(x.exponent + 1))
}

@available(swift, deprecated: 4.2, renamed: "scalbn")
@_transparent
public func ldexp(_ x: Float, _ n : Int) -> Float {
  return Float(sign: .plus, exponent: n, significand: x)
}

@available(swift, deprecated: 4.2, renamed: "scalbn")
@_transparent
public func ldexp(_ x: Double, _ n : Int) -> Double {
  return Double(sign: .plus, exponent: n, significand: x)
}


//  Floating-point properties that are exposed as functions in the C math
//  library. Mark those function names unavailable and direct users to the
//  properties instead.
@available(*, unavailable, message: "use the floatingPointClass property.")
public func fpclassify<T: FloatingPoint>(_ value: T) -> Int { fatalError() }

@available(*, unavailable, message: "use the isNormal property.")
public func isnormal<T: FloatingPoint>(_ value: T) -> Bool { fatalError() }

@available(*, unavailable, message: "use the isFinite property.")
public func isfinite<T: FloatingPoint>(_ value: T) -> Bool { fatalError() }

@available(*, unavailable, message: "use the isInfinite property.")
public func isinf<T: FloatingPoint>(_ value: T) -> Bool { fatalError() }

@available(*, unavailable, message: "use the isNaN property.")
public func isnan<T: FloatingPoint>(_ value: T) -> Bool { fatalError() }

@available(*, unavailable, message: "use the sign property.")
public func signbit<T: FloatingPoint>(_ value: T) -> Int { fatalError() }

@available(swift, deprecated: 4.2/*, obsoleted: 5.1*/, message: "use the exponent property.")
public func ilogb<T: BinaryFloatingPoint>(_ x: T) -> Int {
  return Int(x.exponent)
}


// Unary functions
// Note these do not have a corresponding LLVM intrinsic
@_transparent
public func acos(_ x: Float) -> Float {
  return Float(acosf(CFloat(x)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func acos(_ x: Float80) -> Float80 {
  return Float80(acosl(CLongDouble(x)))
}
#endif

@_transparent
public func asin(_ x: Float) -> Float {
  return Float(asinf(CFloat(x)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func asin(_ x: Float80) -> Float80 {
  return Float80(asinl(CLongDouble(x)))
}
#endif

@_transparent
public func atan(_ x: Float) -> Float {
  return Float(atanf(CFloat(x)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func atan(_ x: Float80) -> Float80 {
  return Float80(atanl(CLongDouble(x)))
}
#endif

@_transparent
public func tan(_ x: Float) -> Float {
  return Float(tanf(CFloat(x)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func tan(_ x: Float80) -> Float80 {
  return Float80(tanl(CLongDouble(x)))
}
#endif

@_transparent
public func acosh(_ x: Float) -> Float {
  return Float(acoshf(CFloat(x)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func acosh(_ x: Float80) -> Float80 {
  return Float80(acoshl(CLongDouble(x)))
}
#endif

@_transparent
public func asinh(_ x: Float) -> Float {
  return Float(asinhf(CFloat(x)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func asinh(_ x: Float80) -> Float80 {
  return Float80(asinhl(CLongDouble(x)))
}
#endif

@_transparent
public func atanh(_ x: Float) -> Float {
  return Float(atanhf(CFloat(x)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func atanh(_ x: Float80) -> Float80 {
  return Float80(atanhl(CLongDouble(x)))
}
#endif

@_transparent
public func cosh(_ x: Float) -> Float {
  return Float(coshf(CFloat(x)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func cosh(_ x: Float80) -> Float80 {
  return Float80(coshl(CLongDouble(x)))
}
#endif

@_transparent
public func sinh(_ x: Float) -> Float {
  return Float(sinhf(CFloat(x)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func sinh(_ x: Float80) -> Float80 {
  return Float80(sinhl(CLongDouble(x)))
}
#endif

@_transparent
public func tanh(_ x: Float) -> Float {
  return Float(tanhf(CFloat(x)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func tanh(_ x: Float80) -> Float80 {
  return Float80(tanhl(CLongDouble(x)))
}
#endif

@_transparent
public func expm1(_ x: Float) -> Float {
  return Float(expm1f(CFloat(x)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func expm1(_ x: Float80) -> Float80 {
  return Float80(expm1l(CLongDouble(x)))
}
#endif

@_transparent
public func log1p(_ x: Float) -> Float {
  return Float(log1pf(CFloat(x)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func log1p(_ x: Float80) -> Float80 {
  return Float80(log1pl(CLongDouble(x)))
}
#endif

@_transparent
public func logb(_ x: Float) -> Float {
  return Float(logbf(CFloat(x)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func logb(_ x: Float80) -> Float80 {
  return Float80(logbl(CLongDouble(x)))
}
#endif

@_transparent
public func cbrt(_ x: Float) -> Float {
  return Float(cbrtf(CFloat(x)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func cbrt(_ x: Float80) -> Float80 {
  return Float80(cbrtl(CLongDouble(x)))
}
#endif

@_transparent
public func erf(_ x: Float) -> Float {
  return Float(erff(CFloat(x)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func erf(_ x: Float80) -> Float80 {
  return Float80(erfl(CLongDouble(x)))
}
#endif

@_transparent
public func erfc(_ x: Float) -> Float {
  return Float(erfcf(CFloat(x)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func erfc(_ x: Float80) -> Float80 {
  return Float80(erfcl(CLongDouble(x)))
}
#endif

@_transparent
public func tgamma(_ x: Float) -> Float {
  return Float(tgammaf(CFloat(x)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func tgamma(_ x: Float80) -> Float80 {
  return Float80(tgammal(CLongDouble(x)))
}
#endif


#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
// Unary intrinsic functions
// Note these have a corresponding LLVM intrinsic
@_transparent
public func cos(_ x: Float) -> Float {
  return _cos(x)
}

@_transparent
public func cos(_ x: Double) -> Double {
  return _cos(x)
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func cos(_ x: Float80) -> Float80 {
  return _cos(x)
}
#endif

@_transparent
public func sin(_ x: Float) -> Float {
  return _sin(x)
}

@_transparent
public func sin(_ x: Double) -> Double {
  return _sin(x)
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func sin(_ x: Float80) -> Float80 {
  return _sin(x)
}
#endif

@_transparent
public func exp(_ x: Float) -> Float {
  return _exp(x)
}

@_transparent
public func exp(_ x: Double) -> Double {
  return _exp(x)
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func exp(_ x: Float80) -> Float80 {
  return _exp(x)
}
#endif

@_transparent
public func exp2(_ x: Float) -> Float {
  return _exp2(x)
}

@_transparent
public func exp2(_ x: Double) -> Double {
  return _exp2(x)
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func exp2(_ x: Float80) -> Float80 {
  return _exp2(x)
}
#endif

@_transparent
public func log(_ x: Float) -> Float {
  return _log(x)
}

@_transparent
public func log(_ x: Double) -> Double {
  return _log(x)
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func log(_ x: Float80) -> Float80 {
  return _log(x)
}
#endif

@_transparent
public func log10(_ x: Float) -> Float {
  return _log10(x)
}

@_transparent
public func log10(_ x: Double) -> Double {
  return _log10(x)
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func log10(_ x: Float80) -> Float80 {
  return _log10(x)
}
#endif

@_transparent
public func log2(_ x: Float) -> Float {
  return _log2(x)
}

@_transparent
public func log2(_ x: Double) -> Double {
  return _log2(x)
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func log2(_ x: Float80) -> Float80 {
  return _log2(x)
}
#endif

@_transparent
public func nearbyint(_ x: Float) -> Float {
  return _nearbyint(x)
}

@_transparent
public func nearbyint(_ x: Double) -> Double {
  return _nearbyint(x)
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func nearbyint(_ x: Float80) -> Float80 {
  return _nearbyint(x)
}
#endif

@_transparent
public func rint(_ x: Float) -> Float {
  return _rint(x)
}

@_transparent
public func rint(_ x: Double) -> Double {
  return _rint(x)
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func rint(_ x: Float80) -> Float80 {
  return _rint(x)
}
#endif

#else
// FIXME: As of now, we cannot declare 64-bit (Double/CDouble) overlays here.
// Since CoreFoundation also exports libc functions, they will conflict with
// Swift overlays when building Foundation. For now, just like normal
// UnaryFunctions, we define overlays only for OverlayFloatTypes.
@_transparent
public func cos(_ x: Float) -> Float {
  return Float(cosf(CFloat(x)))
}
#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func cos(_ x: Float80) -> Float80 {
  return Float80(cosl(CLongDouble(x)))
}
#endif
@_transparent
public func sin(_ x: Float) -> Float {
  return Float(sinf(CFloat(x)))
}
#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func sin(_ x: Float80) -> Float80 {
  return Float80(sinl(CLongDouble(x)))
}
#endif
@_transparent
public func exp(_ x: Float) -> Float {
  return Float(expf(CFloat(x)))
}
#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func exp(_ x: Float80) -> Float80 {
  return Float80(expl(CLongDouble(x)))
}
#endif
@_transparent
public func exp2(_ x: Float) -> Float {
  return Float(exp2f(CFloat(x)))
}
#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func exp2(_ x: Float80) -> Float80 {
  return Float80(exp2l(CLongDouble(x)))
}
#endif
@_transparent
public func log(_ x: Float) -> Float {
  return Float(logf(CFloat(x)))
}
#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func log(_ x: Float80) -> Float80 {
  return Float80(logl(CLongDouble(x)))
}
#endif
@_transparent
public func log10(_ x: Float) -> Float {
  return Float(log10f(CFloat(x)))
}
#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func log10(_ x: Float80) -> Float80 {
  return Float80(log10l(CLongDouble(x)))
}
#endif
@_transparent
public func log2(_ x: Float) -> Float {
  return Float(log2f(CFloat(x)))
}
#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func log2(_ x: Float80) -> Float80 {
  return Float80(log2l(CLongDouble(x)))
}
#endif
@_transparent
public func nearbyint(_ x: Float) -> Float {
  return Float(nearbyintf(CFloat(x)))
}
#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func nearbyint(_ x: Float80) -> Float80 {
  return Float80(nearbyintl(CLongDouble(x)))
}
#endif
@_transparent
public func rint(_ x: Float) -> Float {
  return Float(rintf(CFloat(x)))
}
#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func rint(_ x: Float80) -> Float80 {
  return Float80(rintl(CLongDouble(x)))
}
#endif
#endif

// Binary functions

@_transparent
public func atan2(_ lhs: Float, _ rhs: Float) -> Float {
  return Float(atan2f(CFloat(lhs), CFloat(rhs)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func atan2(_ lhs: Float80, _ rhs: Float80) -> Float80 {
  return Float80(atan2l(CLongDouble(lhs), CLongDouble(rhs)))
}
#endif

@_transparent
public func hypot(_ lhs: Float, _ rhs: Float) -> Float {
  return Float(hypotf(CFloat(lhs), CFloat(rhs)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func hypot(_ lhs: Float80, _ rhs: Float80) -> Float80 {
  return Float80(hypotl(CLongDouble(lhs), CLongDouble(rhs)))
}
#endif

@_transparent
public func pow(_ lhs: Float, _ rhs: Float) -> Float {
  return Float(powf(CFloat(lhs), CFloat(rhs)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func pow(_ lhs: Float80, _ rhs: Float80) -> Float80 {
  return Float80(powl(CLongDouble(lhs), CLongDouble(rhs)))
}
#endif

@_transparent
public func copysign(_ lhs: Float, _ rhs: Float) -> Float {
  return Float(copysignf(CFloat(lhs), CFloat(rhs)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func copysign(_ lhs: Float80, _ rhs: Float80) -> Float80 {
  return Float80(copysignl(CLongDouble(lhs), CLongDouble(rhs)))
}
#endif

@_transparent
public func nextafter(_ lhs: Float, _ rhs: Float) -> Float {
  return Float(nextafterf(CFloat(lhs), CFloat(rhs)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func nextafter(_ lhs: Float80, _ rhs: Float80) -> Float80 {
  return Float80(nextafterl(CLongDouble(lhs), CLongDouble(rhs)))
}
#endif

@_transparent
public func fdim(_ lhs: Float, _ rhs: Float) -> Float {
  return Float(fdimf(CFloat(lhs), CFloat(rhs)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func fdim(_ lhs: Float80, _ rhs: Float80) -> Float80 {
  return Float80(fdiml(CLongDouble(lhs), CLongDouble(rhs)))
}
#endif

@_transparent
public func fmax(_ lhs: Float, _ rhs: Float) -> Float {
  return Float(fmaxf(CFloat(lhs), CFloat(rhs)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func fmax(_ lhs: Float80, _ rhs: Float80) -> Float80 {
  return Float80(fmaxl(CLongDouble(lhs), CLongDouble(rhs)))
}
#endif

@_transparent
public func fmin(_ lhs: Float, _ rhs: Float) -> Float {
  return Float(fminf(CFloat(lhs), CFloat(rhs)))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func fmin(_ lhs: Float80, _ rhs: Float80) -> Float80 {
  return Float80(fminl(CLongDouble(lhs), CLongDouble(rhs)))
}
#endif


//  lgamma not available on Windows, apparently?
#if !os(Windows)
@_transparent
public func lgamma(_ x: Float) -> (Float, Int) {
  var sign = Int32(0)
  let value = lgammaf_r(CFloat(x), &sign)
  return (Float(value), Int(sign))
}
#endif

//  lgamma not available on Windows, apparently?
#if !os(Windows)
@_transparent
public func lgamma(_ x: Double) -> (Double, Int) {
  var sign = Int32(0)
  let value = lgamma_r(CDouble(x), &sign)
  return (Double(value), Int(sign))
}
#endif

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || os(OpenBSD) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func lgamma(_ x: Float80) -> (Float80, Int) {
  var sign = Int32(0)
  let value = lgammal_r(CLongDouble(x), &sign)
  return (Float80(value), Int(sign))
}
#endif


@_transparent
public func remquo(_ x: Float, _ y: Float) -> (Float, Int) {
  var quo = Int32(0)
  let rem = remquof(CFloat(x), CFloat(y), &quo)
  return (Float(rem), Int(quo))
}

@_transparent
public func remquo(_ x: Double, _ y: Double) -> (Double, Int) {
  var quo = Int32(0)
  let rem = remquo(CDouble(x), CDouble(y), &quo)
  return (Double(rem), Int(quo))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@_transparent
public func remquo(_ x: Float80, _ y: Float80) -> (Float80, Int) {
  var quo = Int32(0)
  let rem = remquol(CLongDouble(x), CLongDouble(y), &quo)
  return (Float80(rem), Int(quo))
}
#endif


@available(swift, deprecated: 4.2/*, obsoleted: 5.1*/, message:
           "use Float(nan: Float.RawSignificand).")
@_transparent
@_unavailableInEmbedded
public func nan(_ tag: String) -> Float {
  return Float(nanf(tag))
}

#if (arch(i386) || arch(x86_64)) && !(os(Windows) || os(Android) || ($Embedded && !os(Linux) && !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))))
@available(swift, deprecated: 4.2/*, obsoleted: 5.1*/, message:
           "use Float80(nan: Float80.RawSignificand).")
@_transparent
@_unavailableInEmbedded
public func nan(_ tag: String) -> Float80 {
  return Float80(nanl(tag))
}
#endif


@_transparent
public func jn(_ n: Int, _ x: Double) -> Double {
#if os(Windows)
  return _jn(Int32(n), x)
#else
  return jn(Int32(n), x)
#endif
}

@_transparent
public func yn(_ n: Int, _ x: Double) -> Double {
#if os(Windows)
  return _yn(Int32(n), x)
#else
  return yn(Int32(n), x)
#endif
}

