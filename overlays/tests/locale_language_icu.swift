// Locale.numberingSystem and the ICU-backed Locale.Language members, under Darling.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

let taiwan = Locale.Language(identifier: "zh-TW")
check(taiwan.languageCode == "zh", "Language(identifier:) parses the language code")
check(taiwan.maximalIdentifier == "zh-Hant-TW", "maximalIdentifier adds the likely script (\(taiwan.maximalIdentifier))")
check(Locale.Language(identifier: "en").maximalIdentifier == "en-Latn-US", "maximalIdentifier adds script and region")
check(Locale.Language(identifier: "").maximalIdentifier == "", "maximalIdentifier of an empty identifier")
let components = Locale.Language.Components(identifier: "sr-Cyrl-RS")
check(components.languageCode == "sr" && components.script == Locale.Script("Cyrl") && components.region == Locale.Region("RS"),
      "Language.Components(identifier:)")

check(Locale.Language(identifier: "ar").characterDirection == .rightToLeft, "Arabic is right to left")
check(Locale.Language(identifier: "he-IL").characterDirection == .rightToLeft, "Hebrew is right to left")
check(Locale.Language(identifier: "en-US").characterDirection == .leftToRight, "English is left to right")
check(Locale(identifier: "fa_IR").language.characterDirection == .rightToLeft, "Locale.language.characterDirection")

check(Locale(identifier: "en_US").numberingSystem == "latn", "en_US uses latn (\(Locale(identifier: "en_US").numberingSystem))")
check(Locale(identifier: "ar_EG").numberingSystem == "arab", "ar_EG uses arab (\(Locale(identifier: "ar_EG").numberingSystem))")
check(Locale(identifier: "en_US@numbers=thai").numberingSystem == "thai", "the numbers keyword wins")

print(failures == 0 ? "ALL PASSED" : "\(failures) FAILED")
exit(failures == 0 ? 0 : 1)
