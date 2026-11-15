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

// Bounding boxes below were observed on macOS 26.7.3 for the same calls.
let rectPath = CGMutablePath()
rectPath.addRect(CGRect(x: 0, y: 0, width: 2, height: 3), transform: CGAffineTransform(translationX: 10, y: 20))
check(rectPath.boundingBoxOfPath == CGRect(x: 10, y: 20, width: 2, height: 3), "addRect honours the transform argument")
let roundedPath = CGMutablePath()
roundedPath.addRoundedRect(in: CGRect(x: 0, y: 0, width: 20, height: 30), cornerWidth: 4, cornerHeight: 4,
                           transform: CGAffineTransform(scaleX: 2, y: 1))
check(roundedPath.boundingBoxOfPath == CGRect(x: 0, y: 0, width: 40, height: 30), "addRoundedRect honours the transform argument")
let manyRects = CGMutablePath()
manyRects.addRects([CGRect(x: 0, y: 0, width: 1, height: 1), CGRect(x: 5, y: 5, width: 1, height: 1)], transform: CGAffineTransform(translationX: 1, y: 1))
check(manyRects.boundingBoxOfPath == CGRect(x: 1, y: 1, width: 6, height: 6), "addRects")
let lines = CGMutablePath()
lines.addLines(between: [CGPoint(x: 0, y: 0), CGPoint(x: 4, y: 0), CGPoint(x: 4, y: 3)])
check(lines.boundingBoxOfPath == CGRect(x: 0, y: 0, width: 4, height: 3), "addLines")
let ellipse = CGMutablePath()
ellipse.addEllipse(in: CGRect(x: 0, y: 0, width: 10, height: 6), transform: CGAffineTransform(translationX: 2, y: 0))
check(ellipse.boundingBoxOfPath == CGRect(x: 2, y: 0, width: 10, height: 6), "addEllipse honours the transform argument")
