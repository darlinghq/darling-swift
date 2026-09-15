// PersonNameComponents through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

let empty = PersonNameComponents()
check(empty.namePrefix == nil && empty.givenName == nil && empty.middleName == nil && empty.familyName == nil
      && empty.nameSuffix == nil && empty.nickname == nil && empty.phoneticRepresentation == nil, "init() has no components")

var name = PersonNameComponents()
name.namePrefix = "Dr."
name.givenName = "Johnathan"
name.middleName = "Maple"
name.familyName = "Appleseed"
name.nameSuffix = "Esq."
name.nickname = "Johnny"
check(name.namePrefix == "Dr." && name.givenName == "Johnathan" && name.middleName == "Maple"
      && name.familyName == "Appleseed" && name.nameSuffix == "Esq." && name.nickname == "Johnny", "setters and getters")
name.nickname = nil
check(name.nickname == nil, "setting a component to nil")
name.nickname = "Johnny"

var phonetic = PersonNameComponents()
phonetic.givenName = "JON-uh-thun"
name.phoneticRepresentation = phonetic
check(name.phoneticRepresentation?.givenName == "JON-uh-thun", "phoneticRepresentation round trip")
phonetic.givenName = "changed"
check(name.phoneticRepresentation?.givenName == "JON-uh-thun", "phoneticRepresentation is stored by value")
var nested = name
let beforeNestedWrite = nested
nested.phoneticRepresentation?.givenName = "JOHN"
check(nested.phoneticRepresentation?.givenName == "JOHN" && beforeNestedWrite.phoneticRepresentation?.givenName == "JON-uh-thun"
      && name.phoneticRepresentation?.givenName == "JON-uh-thun", "optional-chained nested write copies on write")

let memberwise = PersonNameComponents(namePrefix: "Dr.", givenName: "Johnathan", middleName: "Maple", familyName: "Appleseed",
                                      nameSuffix: "Esq.", nickname: "Johnny", phoneticRepresentation: phonetic)
check(memberwise.givenName == "Johnathan" && memberwise.nameSuffix == "Esq."
      && memberwise.phoneticRepresentation?.givenName == "changed", "memberwise init")
check(PersonNameComponents(givenName: "Ann").givenName == "Ann" && PersonNameComponents(givenName: "Ann").familyName == nil,
      "memberwise init defaults")

var copy = name
copy.givenName = "Jane"
check(name.givenName == "Johnathan" && copy.givenName == "Jane", "copy on write")

let ns = name._bridgeToObjectiveC()
check(ns.givenName == "Johnathan" && ns.familyName == "Appleseed" && ns.phoneticRepresentation?.givenName == "JON-uh-thun",
      "bridges to NSPersonNameComponents")
ns.givenName = "Mutated"
check(name.givenName == "Johnathan", "bridged object is a copy")

let objc = NSPersonNameComponents()
objc.givenName = "Grace"
objc.familyName = "Hopper"
let fromObjC = PersonNameComponents._unconditionallyBridgeFromObjectiveC(objc)
check(fromObjC.givenName == "Grace" && fromObjC.familyName == "Hopper", "bridges from NSPersonNameComponents")
objc.givenName = "Changed"
check(fromObjC.givenName == "Grace", "bridging from Objective-C copies")
let objcPhonetic = NSPersonNameComponents()
objcPhonetic.givenName = "GRAYS"
objc.phoneticRepresentation = objcPhonetic
let fromObjCNested = PersonNameComponents._unconditionallyBridgeFromObjectiveC(objc)
objc.phoneticRepresentation!.givenName = "X"
check(fromObjCNested.phoneticRepresentation?.givenName == "GRAYS", "bridging from Objective-C copies phoneticRepresentation")
let anyObject: AnyObject = objc
if let cast = anyObject as? PersonNameComponents {
    check(cast.givenName == "Changed", "AnyObject as? PersonNameComponents")
} else {
    check(false, "AnyObject as? PersonNameComponents")
}

let a = PersonNameComponents(givenName: "Ada", familyName: "Lovelace")
let b = PersonNameComponents(givenName: "Ada", familyName: "Lovelace")
let c = PersonNameComponents(givenName: "Alan", familyName: "Turing")
check(a == b && a != c, "equality")
check(PersonNameComponents(namePrefix: "Dr.", givenName: "Ada") != PersonNameComponents(namePrefix: "Ms.", givenName: "Ada"),
      "components differing only in namePrefix are unequal")
check(PersonNameComponents(givenName: "Ada", phoneticRepresentation: PersonNameComponents(givenName: "AY-duh"))
      != PersonNameComponents(givenName: "Ada", phoneticRepresentation: PersonNameComponents(givenName: "AH-dah")),
      "components differing only in phoneticRepresentation are unequal")
check(PersonNameComponents(givenName: "Ada", nickname: "") != PersonNameComponents(givenName: "Ada"),
      "an empty component differs from nil")
check(Set([a, b, c]).count == 2, "Hashable")
check(AnyHashable(a._bridgeToObjectiveC()) == AnyHashable(b), "NSPersonNameComponents as AnyHashable")

check(a.description.contains("givenName: Ada") && a.description.contains("familyName: Lovelace"),
      "description (\(a.description))")

do {
    let data = try JSONEncoder().encode(memberwise)
    let decoded = try JSONDecoder().decode(PersonNameComponents.self, from: data)
    check(decoded.namePrefix == "Dr." && decoded.givenName == "Johnathan" && decoded.middleName == "Maple"
          && decoded.familyName == "Appleseed" && decoded.nameSuffix == "Esq." && decoded.nickname == "Johnny"
          && decoded.phoneticRepresentation == nil, "Codable round trip (phoneticRepresentation isn't encoded)")
    let partial = try JSONDecoder().decode(PersonNameComponents.self, from: Data(#"{"givenName":"Solo"}"#.utf8))
    check(partial.givenName == "Solo" && partial.familyName == nil, "decoding missing components as nil")
} catch {
    check(false, "Codable round trip threw \(error)")
}

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
