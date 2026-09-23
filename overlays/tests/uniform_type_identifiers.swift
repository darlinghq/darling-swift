// UniformTypeIdentifiers overlay: the static types, lookups, conformance, tags, bridging to Darling's
// Objective-C UTType, hashing and Codable. Exits non-zero on failure.

import Foundation
import UniformTypeIdentifiers

var failures = 0
func check(_ ok: Bool, _ what: String) {
	print("\(ok ? "PASS" : "FAIL"): \(what)")
	if !ok { failures += 1 }
}

// The symbols AppZapper 3000 binds to.
check(UTType.folder.identifier == "public.folder", "UTType.folder is public.folder")
check(UTType.folder.conforms(to: .directory) && UTType.folder.conforms(to: .item), "folder conforms to directory and item")
check(!UTType.folder.conforms(to: .data), "folder does not conform to data")
let bridged = UTType.folder._bridgeToObjectiveC()
check(bridged.identifier == "public.folder", "folder bridges to the Objective-C public.folder type")

let identifiers: [(UTType, String)] = [
	(.item, "public.item"), (.data, "public.data"), (.directory, "public.directory"), (.plainText, "public.plain-text"),
	(.json, "public.json"), (.png, "public.png"), (.jpeg, "public.jpeg"), (.pdf, "com.adobe.pdf"),
	(.applicationBundle, "com.apple.application-bundle"), (.zip, "public.zip-archive"), (.threeDContent, "public.3d-content"),
]
for (type, identifier) in identifiers {
	check(type.identifier == identifier, "\(identifier) static type")
}

check(UTType.applicationBundle.conforms(to: .bundle) && UTType.applicationBundle.conforms(to: .package), "app bundle conforms to bundle and package")
check(UTType.png.isSubtype(of: .image) && UTType.image.isSupertype(of: .png), "png is an image")
check(UTType.folder.supertypes.contains(.directory) && UTType.folder.supertypes.contains(.item), "folder supertypes")

check(UTType("public.folder") == .folder, "UTType(\"public.folder\") equals .folder")
check(UTType("PUBLIC.FOLDER") == .folder, "identifiers compare case-insensitively")
check(UTType("not a type") == nil, "an invalid identifier gives nil")

check(UTType(filenameExtension: "txt") == .plainText, "txt is plain text")
check(UTType(filenameExtension: "json") == .json, "json extension")
check(UTType(mimeType: "image/png") == .png, "image/png MIME type")
check(UTType(filenameExtension: "app", conformingTo: .bundle) == .applicationBundle, "app extension conforming to bundle")
let txtImage = UTType(filenameExtension: "txt", conformingTo: .image)
check(txtImage?.isDynamic == true && txtImage?.conforms(to: .image) == true, "txt conforming to image gives a dynamic image type")
check(UTType(tag: "png", tagClass: .filenameExtension, conformingTo: nil) == .png, "tag lookup")
check(UTType.types(tag: "png", tagClass: .filenameExtension, conformingTo: nil).contains(.png), "types(tag:) lookup")
let dynamicType = UTType(filenameExtension: "vdunknownext")
check(dynamicType?.isDynamic == true && dynamicType?.isDeclared == false, "unknown extension gives a dynamic type")
check(UTType.png.isDeclared && !UTType.png.isDynamic && UTType.png.isPublic, "png is declared and public")

check(UTType.png.preferredFilenameExtension == "png", "png preferred extension")
check(UTType.png.preferredMIMEType == "image/png", "png preferred MIME type")
check(UTType.png.tags[.filenameExtension]?.contains("png") == true, "png tags list its extension")
check(UTType.png.tags[.mimeType]?.contains("image/png") == true, "png tags list its MIME type")
check(UTType.folder.preferredFilenameExtension == nil && UTType.folder.tags.isEmpty, "folder has no tags")
check(UTTagClass.filenameExtension.rawValue == "public.filename-extension", "filenameExtension tag class")
check(UTTagClass.mimeType.rawValue == "public.mime-type", "mimeType tag class")

let exported = UTType(exportedAs: "org.darlinghq.test-document", conformingTo: .json)
check(exported.identifier == "org.darlinghq.test-document" && exported.conforms(to: .json), "exported type conforms to its parent")
let imported = UTType(importedAs: "org.darlinghq.test-imported")
check(imported.identifier == "org.darlinghq.test-imported", "imported type keeps its identifier")

let set: Set<UTType> = [.folder, UTType("public.folder")!, .png]
check(set.count == 2, "equal types hash equally")
check(UTType.folder.description == "public.folder", "description is the identifier")

let back = UTType._unconditionallyBridgeFromObjectiveC(bridged)
check(back == .folder, "bridging back from Objective-C")
var conditional: UTType?
check(UTType._conditionallyBridgeFromObjectiveC(UTType.png._bridgeToObjectiveC(), result: &conditional) && conditional == .png, "conditional bridge")

do {
	let data = try JSONEncoder().encode([UTType.folder, .png])
	check(String(decoding: data, as: UTF8.self) == "[\"public.folder\",\"public.png\"]", "UTType encodes as its identifier")
	check(try JSONDecoder().decode([UTType].self, from: data) == [.folder, .png], "UTType Codable round trip")
	let tagData = try JSONEncoder().encode([UTTagClass.mimeType])
	check(try JSONDecoder().decode([UTTagClass].self, from: tagData) == [.mimeType], "UTTagClass Codable round trip")
} catch {
	check(false, "Codable threw \(error)")
}

print("failures=\(failures)")
exit(failures == 0 ? 0 : 1)
