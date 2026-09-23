// Decimal through the Foundation overlay, under Darling. Expected values are from Apple's overlay
// tests (swift-corelibs-foundation Darwin/Foundation-swiftoverlay-Tests/TestDecimal.swift).
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

// The three members AppZapper imports: init(integerLiteral:), / and isZero.
let seven = Decimal(integerLiteral: 7)
let fortyTwo: Decimal = 42
check(seven.description == "7" && fortyTwo.description == "42", "integer literals (\(seven), \(fortyTwo))")
check((-5 as Decimal).description == "-5", "negative literal")
check((1 as Decimal / 3).description == "0.33333333333333333333333333333333333333", "1/3 (\(1 as Decimal / 3))")
check((2 as Decimal / 3).description == "0.66666666666666666666666666666666666666", "2/3 (\(2 as Decimal / 3))")
check((-6 as Decimal / -3) == 2, "-6 / -3")
check((10 as Decimal / 4).description == "2.5", "10 / 4")
check((1 as Decimal / 0).isNaN, "1 / 0 is NaN")
check((65536 as Decimal) / 65536 == 1, "65536 / 65536")
let repeating = (16 as Decimal) / 9
check(((1010 as Decimal) / repeating).description == "568.12500000000000000000000000000248554", "1010 / (16/9) (\((1010 as Decimal) / repeating))")
check(Decimal().isZero && (0 as Decimal).isZero && ((5 as Decimal) - 5).isZero, "isZero for zero values")
check(!(1 as Decimal).isZero && !Decimal.nan.isZero && !(1 as Decimal / 3).isZero, "isZero for nonzero values and NaN")

for i in -2...10 {
    for j in 0...5 {
        check(Decimal(i * j) == Decimal(i) * Decimal(j) && Decimal(i + j) == Decimal(i) + Decimal(j) &&
              Decimal(i - j) == Decimal(i) - Decimal(j), "\(i) op \(j)")
        if j != 0 && i % j == 0 {
            check(Decimal(i) / Decimal(j) == Decimal(i / j), "\(i) / \(j) exact")
        }
    }
}

check(Decimal(2) < Decimal(3) && Decimal(3) > Decimal(2) && Decimal(-9) == Decimal(1) - Decimal(10), "comparison")
check(Decimal(10) < Decimal(11) && Decimal(string: "1.5")! > Decimal(string: "1.25")!, "comparison across exponents")
check(Set([Decimal(1), Decimal(string: "1.0")!, Decimal(2)]).count == 2, "Hashable")
check(abs(Decimal(-1.234)) == Decimal(1.234) && Decimal(-5).magnitude == 5, "abs and magnitude")
check(pow(Decimal(2), 10) == 1024 && pow(Decimal(-2), 3) == -8, "pow")
check(Decimal.pi.description == "3.14159265358979323846264338327950288419", "pi")
check(Decimal(exactly: UInt64.max)?.description == UInt64.max.description, "init(exactly:) UInt64.max")
check(Decimal(sign: .minus, exponent: 10, significand: 3).description == "-30000000000", "init(sign:exponent:significand:)")
check(Decimal(123.458).description == "123.458", "init(Double)")

var bankers = Decimal(), plain = Decimal()
var half = Decimal(string: "2.5")!
NSDecimalRound(&bankers, &half, 0, .bankers)
NSDecimalRound(&plain, &half, 0, .plain)
check(bankers == 2 && plain == 3, "NSDecimalRound bankers and plain (\(bankers), \(plain))")

check(Decimal(string: "123.456e2") == Decimal(string: "12345.6"), "init(string:) with exponent")
check(Decimal(string: "abc") == nil, "init(string:) rejects garbage")

let number = Decimal(string: "12.75")! as NSDecimalNumber
check(number.decimalValue == Decimal(string: "12.75")! && (number as Decimal) == Decimal(string: "12.75")!, "NSDecimalNumber bridging")

let encoded = try! JSONEncoder().encode([Decimal(string: "0.1")!])
check(try! JSONDecoder().decode([Decimal].self, from: encoded) == [Decimal(string: "0.1")!], "Codable round trip")

print(failures == 0 ? "PASS" : "FAIL: \(failures)")
exit(failures == 0 ? 0 : 1)
