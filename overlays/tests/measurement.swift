// Copyright (C) 2026 Lubos Dolezel
//
// Measurement and the Unit family (Unit, Dimension, UnitConverter, UnitConverterLinear, UnitLength, ...) through the
// Foundation overlay, written from the documented API: conversion between the units of one dimension, arithmetic,
// comparison, the temperature scales' offsets, NSMeasurement bridging and Codable. PASS/FAIL lines; exit status 1 on
// any failure.
import Foundation

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "PASS:" : "FAIL:", label)
    if !condition { failures += 1 }
}
func near(_ a: Double, _ b: Double, _ eps: Double = 1e-9) -> Bool { abs(a - b) <= eps * max(1, abs(b)) }

// The family has the macOS Swift spellings.
let kilometers: Unit = UnitLength.kilometers
check(kilometers.symbol == "km", "UnitLength.kilometers is a Unit with symbol km")
let meters: Dimension = UnitLength.meters
check(type(of: meters.converter) is UnitConverterLinear.Type, "UnitLength.meters is a Dimension with a UnitConverterLinear")
check(UnitLength.baseUnit() == UnitLength.meters, "the base unit of UnitLength is meters")

// Conversion.
let oneMile = Measurement(value: 1, unit: UnitLength.miles)
check(near(oneMile.converted(to: .kilometers).value, 1.609344), "1 mi converts to 1.609344 km")
var length = Measurement(value: 2.5, unit: UnitLength.kilometers)
length.convert(to: .meters)
check(near(length.value, 2500) && length.unit == UnitLength.meters, "convert(to:) converts in place")
check(near(Measurement(value: 100, unit: UnitTemperature.celsius).converted(to: .fahrenheit).value, 212), "100 C is 212 F")
check(near(Measurement(value: 0, unit: UnitTemperature.kelvin).converted(to: .celsius).value, -273.15), "0 K is -273.15 C")
check(near(Measurement(value: 90, unit: UnitDuration.minutes).converted(to: .hours).value, 1.5), "90 min is 1.5 h")
check(near(Measurement(value: 1, unit: UnitMass.kilograms).converted(to: .grams).value, 1000), "1 kg is 1000 g")

// Arithmetic. Across units of one dimension the result is in the dimension's base unit.
let km = Measurement(value: 1, unit: UnitLength.kilometers)
let m500 = Measurement(value: 500, unit: UnitLength.meters)
check(near((km + m500).value, 1500) && (km + m500).unit == UnitLength.meters, "1 km + 500 m is 1500 m")
check(near((km - m500).value, 500), "1 km - 500 m is 500 m")
let sameUnit = Measurement(value: 2, unit: UnitLength.meters) + Measurement(value: 3, unit: UnitLength.meters)
check(sameUnit.value == 5 && sameUnit.unit == UnitLength.meters, "same units add without conversion")
check((km * 2).value == 2 && (2 * km).value == 2 && (km / 4).value == 0.25, "scalar * and /")

// Comparison.
check(km == Measurement(value: 1000, unit: UnitLength.meters), "1 km == 1000 m")
check(km > m500 && m500 < km && km >= Measurement(value: 1000, unit: UnitLength.meters), "ordering across units")
check(Measurement(value: 1, unit: UnitLength.meters) != Measurement(value: 2, unit: UnitLength.meters), "different values differ")
check(Set([km, Measurement(value: 1000, unit: UnitLength.meters), m500]).count >= 2, "usable in a Set")

// Text.
check(Measurement(value: 5, unit: UnitLength.meters).description == "5.0 m", "description is value and symbol")

// Custom dimensions through the public initialisers.
let furlongs = UnitLength(symbol: "fur", converter: UnitConverterLinear(coefficient: 201.168))
check(near(Measurement(value: 1, unit: furlongs).converted(to: .meters).value, 201.168), "a custom UnitLength converts")
let offset = UnitConverterLinear(coefficient: 2, constant: 10)
check(offset.baseUnitValue(fromValue: 3) == 16 && near(offset.value(fromBaseUnitValue: 16), 3), "UnitConverterLinear: base = value * coefficient + constant")

// NSMeasurement bridging.
let bridged = km as NSMeasurement
check(bridged.doubleValue == 1 && bridged.unit.symbol == "km", "bridges to NSMeasurement")
let back: Measurement<UnitLength> = bridged as Measurement<UnitLength>
check(back == km, "NSMeasurement bridges back to Measurement<UnitLength>")

// Codable.
do {
    let data = try JSONEncoder().encode(km)
    let decoded = try JSONDecoder().decode(Measurement<UnitLength>.self, from: data)
    check(decoded == km && decoded.unit.symbol == "km", "Codable round trip keeps the value and unit")
} catch {
    check(false, "Codable threw \(error)")
}

exit(failures == 0 ? 0 : 1)
