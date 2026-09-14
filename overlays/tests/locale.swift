// Locale through the Foundation overlay, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

let us = Locale(identifier: "en_US")
check(us.identifier == "en_US", "init(identifier:) (\(us.identifier))")
check(us.languageCode == "en", "languageCode (\(String(describing: us.languageCode)))")
check(us.regionCode == "US", "regionCode (\(String(describing: us.regionCode)))")
check(Locale(identifier: "fr").regionCode == nil, "no region code")

// Darling's container may have no user locale or language defaults, so compare with what NSLocale reports.
let current = Locale.current
let objcCurrent = (NSLocale.currentLocale() as! NSLocale).localeIdentifier() ?? ""
check(current.identifier == objcCurrent, "Locale.current matches +[NSLocale currentLocale] (\"\(current.identifier)\")")
check(Locale.autoupdatingCurrent == Locale.autoupdatingCurrent, "autoupdatingCurrent equals itself")
check(Locale.autoupdatingCurrent != us, "autoupdatingCurrent differs from a fixed locale")
check(us == Locale(identifier: "en_US") && us != Locale(identifier: "de_DE"), "equality")
check(Set([us, Locale(identifier: "en_US"), Locale(identifier: "de_DE")]).count == 2, "Hashable")

check(!Locale.availableIdentifiers.isEmpty, "availableIdentifiers (\(Locale.availableIdentifiers.count))")
check(Locale.preferredLanguages.count == (NSLocale.preferredLanguages() ?? []).count, "preferredLanguages matches +[NSLocale preferredLanguages] (\(Locale.preferredLanguages))")
let deComponents = Locale.components(fromIdentifier: "de_DE")
check(deComponents[NSLocaleLanguageCode] == "de" && deComponents[NSLocaleCountryCode] == "DE",
      "components(fromIdentifier:) (\(deComponents))")
check(Locale.identifier(fromComponents: deComponents) == "de_DE", "identifier(fromComponents:)")

let name = us.localizedString(forLanguageCode: "fr")
check(name != nil && !name!.isEmpty, "localizedString(forLanguageCode:) (\(String(describing: name)))")
let idName = us.localizedString(forIdentifier: "de_DE")
check(idName != nil && !idName!.isEmpty, "localizedString(forIdentifier:) (\(String(describing: idName)))")

let ns = us as NSLocale
check(ns.localeIdentifier() == "en_US", "Locale bridges to NSLocale")
check((ns as Locale) == us, "NSLocale bridges back")
check(us.description.hasPrefix("en_US"), "description (\(us.description))")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
