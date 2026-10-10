// CoreGraphics Swift geometry members under Darling.
import CoreGraphics

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { fatalError(message) }
}

let rect = CGRect(x: 10, y: 20, width: 30, height: 40)
check(rect.minX == 10 && rect.maxX == 40, "horizontal bounds")
check(rect.minY == 20 && rect.maxY == 60, "vertical bounds")
check(rect.contains(CGPoint(x: 15, y: 25)), "point containment")
check(!rect.contains(CGPoint(x: 40, y: 25)), "maximum edge is excluded")

let transform = CGAffineTransform.identity.translatedBy(x: 3, y: 4)
check(transform.tx == 3 && transform.ty == 4, "translation")
check(!transform.isIdentity, "translated transform is not identity")

let mutablePath = CGMutablePath()
mutablePath.move(to: CGPoint(x: 1, y: 2))
mutablePath.addLine(to: CGPoint(x: 11, y: 2), transform: CGAffineTransform(translationX: 0, y: 5))
let subpath = CGMutablePath()
subpath.move(to: .zero)
subpath.addLine(to: CGPoint(x: 4, y: 4))
mutablePath.addPath(subpath, transform: .identity)
check(!mutablePath.isEmpty, "mutable path has elements")
check(mutablePath.boundingBoxOfPath.maxY == 7, "addLine honours the transform argument")

let curves = CGMutablePath()
curves.move(to: .zero)
curves.addQuadCurve(to: CGPoint(x: 10, y: 0), control: CGPoint(x: 5, y: 5), transform: CGAffineTransform(translationX: 0, y: 100))
check(curves.boundingBoxOfPath.maxY >= 100, "addQuadCurve honours the transform argument")
let cubic = CGMutablePath()
cubic.move(to: .zero)
cubic.addCurve(to: CGPoint(x: 10, y: 0), control1: CGPoint(x: 2, y: 5), control2: CGPoint(x: 8, y: 5), transform: CGAffineTransform(translationX: 50, y: 0))
check(cubic.boundingBoxOfPath.maxX >= 60, "addCurve honours the transform argument")
