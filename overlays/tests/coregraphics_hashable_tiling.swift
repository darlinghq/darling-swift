import CoreGraphics

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

// CGRect: Hashable agrees with ==, which compares standardized rects and treats all null rects as equal.
let rect = CGRect(x: 1, y: 2, width: 3, height: 4)
let flipped = CGRect(x: 4, y: 6, width: -3, height: -4)
check(rect == flipped && rect.hashValue == flipped.hashValue, "standardized rects hash equally")
let nulls: Set<CGRect> = [.null, CGRect(x: CGFloat.infinity, y: 0, width: 1, height: 1)]
check(nulls.count == 1, "null rects collapse in a Set")
check(Set([rect, flipped, .zero]).count == 2, "Set dedupes equal rects")

// draw(_:in:byTiling:) with byTiling false draws the image like draw(_:in:).
let space = CGColorSpaceCreateDeviceRGB()
let premultipliedLast: UInt32 = 1
let source = CGBitmapContextCreate(nil, 1, 1, 8, 4, space, premultipliedLast)!.takeRetainedValue()
CGContextSetRGBFillColor(source, 1, 0, 0, 1)
CGContextFillRect(source, CGRect(x: 0, y: 0, width: 1, height: 1))
let image = source.makeImage()!
let target = CGBitmapContextCreate(nil, 2, 2, 8, 8, space, premultipliedLast)!.takeRetainedValue()
target.draw(image, in: CGRect(x: 0, y: 0, width: 2, height: 2), byTiling: false)
let pixels = CGBitmapContextGetData(target)!.assumingMemoryBound(to: UInt8.self)
check(pixels[0] == 255 && pixels[1] == 0 && pixels[2] == 0 && pixels[3] == 255 && pixels[12] == 255,
      "draw(_:in:byTiling: false) fills the rect (\(pixels[0]), \(pixels[1]), \(pixels[2]), \(pixels[3]))")

if failures == 0 {
    print("ALL PASSED")
} else {
    exit(1)
}
