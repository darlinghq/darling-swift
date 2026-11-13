import CoreGraphics

let white = CGColor.white
let black = CGColor.black
let clear = CGColor.clear

guard white.alpha == 1, black.alpha == 1, clear.alpha == 0,
      white.components == [1, 1], black.components == [0, 1] else {
    fatalError("CoreGraphics system color values are incorrect")
}
