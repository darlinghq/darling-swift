//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// String.Encoding and the NSString-backed String/StringProtocol APIs apps import, based on release/5.4
// stdlib/public/Darwin/Foundation/NSStringEncodings.swift and NSStringAPI.swift.
// Darling:
// - Current SDKs declare these on an unconstrained `extension StringProtocol` taking `Range<String.Index>` (that's how
//   apps' symbols are mangled), not on the 5.4 overlay's `where Index == String.Index` extension, so index
//   conversions go through the UTF-16 view of the receiver.
// - Darling's NSString lacks -stringByAddingPercentEncodingWithAllowedCharacters:, -stringByRemovingPercentEncoding
//   and the localized case properties, so those are implemented in Swift. Its selectors import with their ObjC
//   spellings (uppercaseString(with:), componentsSeparatedByCharacters(in:), data(usingEncoding:)).

@_exported import Foundation // Clang module

extension String {
  public struct Encoding : RawRepresentable {
    public var rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let ascii = Encoding(rawValue: 1)
    public static let nextstep = Encoding(rawValue: 2)
    public static let japaneseEUC = Encoding(rawValue: 3)
    public static let utf8 = Encoding(rawValue: 4)
    public static let isoLatin1 = Encoding(rawValue: 5)
    public static let symbol = Encoding(rawValue: 6)
    public static let nonLossyASCII = Encoding(rawValue: 7)
    public static let shiftJIS = Encoding(rawValue: 8)
    public static let isoLatin2 = Encoding(rawValue: 9)
    public static let unicode = Encoding(rawValue: 10)
    public static let windowsCP1251 = Encoding(rawValue: 11)
    public static let windowsCP1252 = Encoding(rawValue: 12)
    public static let windowsCP1253 = Encoding(rawValue: 13)
    public static let windowsCP1254 = Encoding(rawValue: 14)
    public static let windowsCP1250 = Encoding(rawValue: 15)
    public static let iso2022JP = Encoding(rawValue: 21)
    public static let macOSRoman = Encoding(rawValue: 30)
    public static let utf16 = Encoding.unicode
    public static let utf16BigEndian = Encoding(rawValue: 0x90000100)
    public static let utf16LittleEndian = Encoding(rawValue: 0x94000100)
    public static let utf32 = Encoding(rawValue: 0x8c000100)
    public static let utf32BigEndian = Encoding(rawValue: 0x98000100)
    public static let utf32LittleEndian = Encoding(rawValue: 0x9c000100)
  }

  public typealias EnumerationOptions = NSStringEnumerationOptions
  public typealias CompareOptions = NSStringCompareOptions
}

extension String.Encoding : Hashable {
  public var hashValue: Int {
    return rawValue.hashValue
  }

  @_alwaysEmitIntoClient
  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }

  public static func ==(lhs: String.Encoding, rhs: String.Encoding) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }
}

extension String.Encoding : CustomStringConvertible {
  // Darling: NSString has no +localizedNameOfStringEncoding:, so the raw value is shown.
  public var description: String {
    return "String.Encoding(rawValue: \(rawValue))"
  }
}

extension String {
  /// Returns a `String` initialized by converting given `data` into
  /// Unicode characters using a given `encoding`.
  public init?(data: __shared Data, encoding: Encoding) {
    guard let s = NSString(data: data, encoding: encoding.rawValue) else { return nil }
    self = String._unconditionallyBridgeFromObjectiveC(s)
  }

  /// Returns a `Data` containing a representation of
  /// the `String` encoded using a given encoding.
  public func data(using encoding: Encoding, allowLossyConversion: Bool = false) -> Data? {
    if encoding == .utf8 {
      return Data(self.utf8)
    }
    guard let d = _bridgeToObjectiveC().data(usingEncoding: encoding.rawValue, allowLossyConversion: allowLossyConversion) else {
      return nil
    }
    return d
  }
}

// NSStringCompareOptions values (NSString.h), which Darling's NS_OPTIONS import as a raw-value struct.
private let _caseInsensitiveSearch = NSStringCompareOptions(rawValue: 1)
private let _diacriticInsensitiveSearch = NSStringCompareOptions(rawValue: 128)

extension StringProtocol {
  //===--- Bridging helpers -----------------------------------------------===//

  fileprivate var _ns: NSString {
    return String(self)._bridgeToObjectiveC()
  }

  /// The UTF-16 offset of `index` from the start of `self`.
  fileprivate func _utf16Offset(of index: String.Index) -> Int {
    if let s = self as? Substring {
      return s.utf16.distance(from: s.startIndex, to: index)
    }
    let s = String(self)
    return s.utf16.distance(from: s.startIndex, to: index)
  }

  /// The index of `self` at a UTF-16 offset from its start.
  fileprivate func _index(utf16Offset offset: Int) -> String.Index {
    if let s = self as? Substring {
      return s.utf16.index(s.startIndex, offsetBy: offset)
    }
    let s = String(self)
    return s.utf16.index(s.startIndex, offsetBy: offset)
  }

  fileprivate func _nsRange(_ range: Range<String.Index>?) -> NSRange {
    guard let range = range else {
      return NSRange(location: 0, length: utf16.count)
    }
    let lower = _utf16Offset(of: range.lowerBound)
    return NSRange(location: lower, length: _utf16Offset(of: range.upperBound) - lower)
  }

  fileprivate func _range(_ range: NSRange) -> Range<String.Index>? {
    guard range.location != NSNotFound else { return nil }
    return _index(utf16Offset: range.location)..<_index(utf16Offset: range.location + range.length)
  }

  //===--- Case -------------------------------------------------------------===//

  /// A copy of the string with each word changed to its corresponding capitalized spelling.
  public var capitalized: String {
    return _ns.capitalized()
  }

  /// A capitalized representation of the string that is produced using the current locale.
  public var localizedCapitalized: String {
    return _ns.capitalizedString(with: NSLocale.currentLocale() as? NSLocale)
  }

  /// A lowercase version of the string that is produced using the current locale.
  public var localizedLowercase: String {
    return _ns.lowercaseString(with: NSLocale.currentLocale() as? NSLocale)
  }

  /// An uppercase version of the string that is produced using the current locale.
  public var localizedUppercase: String {
    return _ns.uppercaseString(with: NSLocale.currentLocale() as? NSLocale)
  }

  /// Returns a version of the string with all letters converted to uppercase, taking into account the specified
  /// locale.
  public func uppercased(with locale: Locale?) -> String {
    return _ns.uppercaseString(with: locale?._bridgeToObjectiveC())
  }

  //===--- Comparison -------------------------------------------------------===//

  /// Returns the result of invoking `compare:options:` with `NSCaseInsensitiveSearch` as the only option.
  public func caseInsensitiveCompare<T : StringProtocol>(_ aString: T) -> ComparisonResult {
    return _ns.caseInsensitiveCompare(String(aString))
  }

  /// Compares the string and the given string using a case-insensitive, localized, comparison.
  public func localizedCaseInsensitiveCompare<T : StringProtocol>(_ aString: T) -> ComparisonResult {
    return _ns.localizedCaseInsensitiveCompare(String(aString))
  }

  /// Compares the string and the given string as sorted by the Finder.
  public func localizedStandardCompare<T : StringProtocol>(_ string: T) -> ComparisonResult {
    return _ns.localizedStandardCompare(String(string))
  }

  /// Compares the string using the specified options and returns the lexical ordering for the range.
  public func compare<T : StringProtocol>(
    _ aString: T,
    options mask: String.CompareOptions = String.CompareOptions(rawValue: 0),
    range: Range<String.Index>? = nil,
    locale: Locale? = nil
  ) -> ComparisonResult {
    let other = String(aString)
    if let locale = locale {
      return _ns.compare(other, options: mask, range: _nsRange(range), locale: locale._bridgeToObjectiveC())
    }
    return _ns.compare(other, options: mask, range: _nsRange(range))
  }

  //===--- Searching --------------------------------------------------------===//

  /// Finds and returns the range of the first occurrence of a given string within a given range of the `String`,
  /// subject to given options, using the specified locale, if any.
  public func range<T : StringProtocol>(
    of aString: T,
    options mask: String.CompareOptions = String.CompareOptions(rawValue: 0),
    range searchRange: Range<String.Index>? = nil,
    locale: Locale? = nil
  ) -> Range<String.Index>? {
    let other = String(aString)
    let result: NSRange
    if let locale = locale {
      result = _ns.range(of: other, options: mask, range: _nsRange(searchRange), locale: locale._bridgeToObjectiveC())
    } else {
      result = _ns.range(of: other, options: mask, range: _nsRange(searchRange))
    }
    return _range(result)
  }

  /// Finds and returns the range of the first occurrence of a given string, taking the current locale into account.
  public func localizedStandardRange<T : StringProtocol>(of string: T) -> Range<String.Index>? {
    return range(of: string, options: NSStringCompareOptions(rawValue: _caseInsensitiveSearch.rawValue | _diacriticInsensitiveSearch.rawValue),
                 locale: Locale.current)
  }

  /// Returns `true` if `other` is non-empty and contained within `self` by case-sensitive, non-literal search.
  public func contains<T : StringProtocol>(_ other: T) -> Bool {
    return range(of: other) != nil
  }

  /// Returns a Boolean value indicating whether the given string is non-empty and contained within this string by
  /// case-insensitive, non-literal search, taking into account the current locale.
  public func localizedCaseInsensitiveContains<T : StringProtocol>(_ other: T) -> Bool {
    return range(of: other, options: _caseInsensitiveSearch, locale: Locale.current) != nil
  }

  /// Returns a Boolean value indicating whether the string contains the given string, taking the current locale
  /// into account (case and diacritic insensitive).
  public func localizedStandardContains<T : StringProtocol>(_ string: T) -> Bool {
    return localizedStandardRange(of: string) != nil
  }

  /// Finds and returns the range in the `String` of the first character from a given character set found in a
  /// given range with given options.
  public func rangeOfCharacter(
    from aSet: CharacterSet,
    options mask: String.CompareOptions = String.CompareOptions(rawValue: 0),
    range aRange: Range<String.Index>? = nil
  ) -> Range<String.Index>? {
    return _range(_ns.rangeOfCharacter(from: aSet._bridgeToObjectiveC(), options: mask, range: _nsRange(aRange)))
  }

  //===--- Splitting, trimming and replacing ---------------------------------===//

  /// Returns an array containing substrings from the string that have been divided by the given separator.
  public func components<T : StringProtocol>(separatedBy separator: T) -> [String] {
    return (_ns.components(separatedBy: String(separator)) ?? []).compactMap { $0 as? String }
  }

  /// Returns an array containing substrings from the string that have been divided by characters in the given set.
  public func components(separatedBy separator: CharacterSet) -> [String] {
    return (_ns.componentsSeparatedByCharacters(in: separator._bridgeToObjectiveC()) ?? []).compactMap { $0 as? String }
  }

  /// Returns a new string made by removing from both ends of the `String` characters contained in a given
  /// character set.
  public func trimmingCharacters(in set: CharacterSet) -> String {
    return _ns.trimmingCharacters(in: set._bridgeToObjectiveC())
  }

  /// Returns a new string in which all occurrences of a target string in a specified range of the string are
  /// replaced by another given string.
  public func replacingOccurrences<Target : StringProtocol, Replacement : StringProtocol>(
    of target: Target,
    with replacement: Replacement,
    options: String.CompareOptions = String.CompareOptions(rawValue: 0),
    range searchRange: Range<String.Index>? = nil
  ) -> String {
    return _ns.replacingOccurrences(of: String(target), with: String(replacement), options: options,
                                    range: _nsRange(searchRange))
  }

  /// Returns a new string formed from the `String` by either removing characters from the end, or by appending as
  /// many occurrences as necessary of a given pad string.
  public func padding<T : StringProtocol>(toLength newLength: Int, withPad padString: T, startingAt padIndex: Int) -> String {
    return _ns.padding(toLength: newLength, with: String(padString), startingAt: padIndex)
  }

  /// Enumerates the substrings of the specified type in the specified range of the string.
  public func enumerateSubstrings<R : RangeExpression>(
    in range: R,
    options opts: String.EnumerationOptions = String.EnumerationOptions(rawValue: 0),
    _ body: @escaping (_ substring: String?, _ substringRange: Range<String.Index>,
                       _ enclosingRange: Range<String.Index>, inout Bool) -> Void
  ) where R.Bound == String.Index {
    let bounds = (self as? Substring).map { range.relative(to: $0) } ?? range.relative(to: String(self))
    _ns.enumerateSubstrings(in: _nsRange(bounds), options: opts) { substring, substringRange, enclosingRange, stop in
      var stop_ = false
      body(substring, self._range(substringRange)!, self._range(enclosingRange)!, &stop_)
      if stop_ {
        stop?.pointee = true
      }
    }
  }

  //===--- Normalization and hashing ----------------------------------------===//

  /// A string created by normalizing the string's contents using Form KD.
  public var decomposedStringWithCompatibilityMapping: String {
    return _ns.decomposedStringWithCompatibilityMapping()
  }

  /// An unsigned integer that can be used as a hash table address.
  public var hash: Int {
    return _ns.hash
  }

  //===--- Encodings and percent encoding ------------------------------------===//

  /// Returns a representation of the string as a C string using a given encoding.
  public func cString(using encoding: String.Encoding) -> [CChar]? {
    let ns = _ns
    return withExtendedLifetime(ns) {
      guard let p = ns.cString(usingEncoding: encoding.rawValue) else { return nil }
      return Array(UnsafeBufferPointer(start: p, count: strlen(p) + 1))
    }
  }

  /// Returns a new string created by replacing all characters in the string not in the specified set with percent
  /// encoded characters.
  public func addingPercentEncoding(withAllowedCharacters allowedCharacters: CharacterSet) -> String? {
    var result = ""
    for byte in utf8 {
      if byte < 0x80, allowedCharacters.contains(Unicode.Scalar(byte)) {
        result.unicodeScalars.append(Unicode.Scalar(byte))
      } else {
        let hex = String(byte, radix: 16, uppercase: true)
        result += byte < 16 ? "%0" + hex : "%" + hex
      }
    }
    return result
  }

  /// A new string made from the string by replacing all percent encoded sequences with the matching UTF-8
  /// characters.
  public var removingPercentEncoding: String? {
    return _percentDecode(String(self))
  }

  //===--- Writing ----------------------------------------------------------===//

  /// Writes the contents of the `String` to the URL specified by url using the specified encoding.
  public func write(to url: URL, atomically useAuxiliaryFile: Bool, encoding enc: String.Encoding) throws {
    try _ns.write(to: url._bridgeToObjectiveC(), atomically: useAuxiliaryFile, encoding: enc.rawValue)
  }
}
