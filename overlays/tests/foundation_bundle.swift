import Foundation

let bundle: Bundle = .main
guard let path = bundle.bundlePath, !path.isEmpty else {
    fatalError("main bundle has no path")
}

let key = "darling.bundle.missing.localization"
let localized = NSLocalizedString(key, comment: "Bundle Swift import smoke test")
guard localized == key else {
    fatalError("missing localization did not fall back to its key")
}
