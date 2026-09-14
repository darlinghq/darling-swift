// URLComponents and URLQueryItem for Darling, written from the public Foundation API documentation and RFC 3986.
// Darling's NSURLComponents only implements scheme, host and URL, and NSURLQueryItem has no API, so instead of
// wrapping them (as the release/5.4 overlay does) these value types parse and build URL strings in Swift. The
// Objective-C bridging to NSURLComponents/NSURLQueryItem is therefore not provided.

@_exported import Foundation // Clang module

/// Character classes from RFC 3986 used when percent-encoding URL components.
private enum _URLComponentAllowed {
    static let unreserved: Set<UInt8> = {
        var s = Set<UInt8>()
        for c in UInt8(ascii: "a")...UInt8(ascii: "z") { s.insert(c) }
        for c in UInt8(ascii: "A")...UInt8(ascii: "Z") { s.insert(c) }
        for c in UInt8(ascii: "0")...UInt8(ascii: "9") { s.insert(c) }
        for c in "-._~".utf8 { s.insert(c) }
        return s
    }()
    static let subDelims = Set("!$&'()*+,;=".utf8)

    static let user = unreserved.union(subDelims).subtracting([UInt8(ascii: ":")])
    static let password = unreserved.union(subDelims)
    static let host = unreserved.union(subDelims).union(":[]".utf8)
    static let path = unreserved.union(subDelims).union(":@/".utf8).subtracting([UInt8(ascii: ";")])
    static let query = unreserved.union(subDelims).union(":@/?".utf8)
    static let fragment = query
    static let scheme: Set<UInt8> = unreserved.subtracting("_~".utf8).union("+".utf8)
}

private func _percentEncode(_ string: String, allowed: Set<UInt8>) -> String {
    var result = ""
    result.reserveCapacity(string.utf8.count)
    for byte in string.utf8 {
        if allowed.contains(byte) {
            result.unicodeScalars.append(Unicode.Scalar(byte))
        } else {
            let hex = String(byte, radix: 16, uppercase: true)
            result += byte < 16 ? "%0" + hex : "%" + hex
        }
    }
    return result
}

private func _hexValue(_ byte: UInt8) -> UInt8? {
    switch byte {
    case UInt8(ascii: "0")...UInt8(ascii: "9"): return byte - UInt8(ascii: "0")
    case UInt8(ascii: "a")...UInt8(ascii: "f"): return byte - UInt8(ascii: "a") + 10
    case UInt8(ascii: "A")...UInt8(ascii: "F"): return byte - UInt8(ascii: "A") + 10
    default: return nil
    }
}

/// Decodes percent escapes; returns nil for a malformed escape or bytes that aren't valid UTF-8.
private func _percentDecode(_ string: String) -> String? {
    var bytes: [UInt8] = []
    bytes.reserveCapacity(string.utf8.count)
    var iterator = string.utf8.makeIterator()
    while let byte = iterator.next() {
        if byte == UInt8(ascii: "%") {
            guard let hi = iterator.next().flatMap(_hexValue), let lo = iterator.next().flatMap(_hexValue) else {
                return nil
            }
            bytes.append(hi << 4 | lo)
        } else {
            bytes.append(byte)
        }
    }
    return String(validating: bytes, as: UTF8.self)
}

/// True if `string` only contains `allowed` bytes and well-formed percent escapes.
private func _isValidPercentEncoded(_ string: String, allowed: Set<UInt8>) -> Bool {
    let bytes = Array(string.utf8)
    var i = 0
    while i < bytes.count {
        if bytes[i] == UInt8(ascii: "%") {
            guard i + 2 < bytes.count, _hexValue(bytes[i + 1]) != nil, _hexValue(bytes[i + 2]) != nil else { return false }
            i += 3
        } else {
            guard allowed.contains(bytes[i]) else { return false }
            i += 1
        }
    }
    return true
}

/// A structure that parses URLs into and constructs URLs from their constituent parts (RFC 3986).
public struct URLComponents : Hashable, Equatable {
    private var _scheme: String?
    private var _user: String?
    private var _password: String?
    private var _host: String?
    private var _port: Int?
    private var _path: String = ""
    private var _query: String?
    private var _fragment: String?

    /// Initialize with all components undefined.
    public init() {}

    /// Initialize with a URL string. Returns nil if the string isn't a valid URL string.
    public init?(string: __shared String) {
        var rest = Substring(string)

        // scheme ":" — only when the first ':' comes before any of "/?#" and the scheme is well formed.
        if let colon = rest.firstIndex(of: ":"),
           !rest[..<colon].contains(where: { $0 == "/" || $0 == "?" || $0 == "#" }) {
            let scheme = String(rest[..<colon])
            guard let first = scheme.utf8.first, (UInt8(ascii: "a")...UInt8(ascii: "z")).contains(first | 0x20),
                  scheme.utf8.allSatisfy({ _URLComponentAllowed.scheme.contains($0) }) else { return nil }
            _scheme = scheme
            rest = rest[rest.index(after: colon)...]
        }

        if let hash = rest.firstIndex(of: "#") {
            _fragment = String(rest[rest.index(after: hash)...])
            rest = rest[..<hash]
        }
        if let question = rest.firstIndex(of: "?") {
            _query = String(rest[rest.index(after: question)...])
            rest = rest[..<question]
        }

        if rest.hasPrefix("//") {
            rest = rest.dropFirst(2)
            let authorityEnd = rest.firstIndex(of: "/") ?? rest.endIndex
            var authority = rest[..<authorityEnd]
            rest = rest[authorityEnd...]

            if let at = authority.lastIndex(of: "@") {
                let userInfo = authority[..<at]
                if let colon = userInfo.firstIndex(of: ":") {
                    _user = String(userInfo[..<colon])
                    _password = String(userInfo[userInfo.index(after: colon)...])
                } else {
                    _user = String(userInfo)
                }
                authority = authority[authority.index(after: at)...]
            }

            var hostPart = authority
            if authority.hasPrefix("[") {
                guard let close = authority.firstIndex(of: "]") else { return nil }
                hostPart = authority[...close]
                let afterHost = authority[authority.index(after: close)...]
                if !afterHost.isEmpty {
                    guard afterHost.hasPrefix(":") else { return nil }
                    guard let port = Self._parsePort(afterHost.dropFirst()) else { return nil }
                    _port = port
                }
            } else if let colon = authority.lastIndex(of: ":") {
                hostPart = authority[..<colon]
                guard let port = Self._parsePort(authority[authority.index(after: colon)...]) else { return nil }
                _port = port
            }
            _host = String(hostPart)
        }
        _path = String(rest)

        guard Self._validate(user: _user, password: _password, host: _host, path: _path, query: _query, fragment: _fragment) else {
            return nil
        }
    }

    /// Initialize with the components of a URL. If `resolve` is true and the URL is relative, the components of its
    /// absolute URL are used.
    public init?(url: __shared URL, resolvingAgainstBaseURL resolve: Bool) {
        self.init(string: resolve ? url.absoluteString : url.relativeString)
    }

    private static func _parsePort(_ digits: Substring) -> Int?? {
        if digits.isEmpty { return .some(nil) }
        guard digits.utf8.allSatisfy({ (UInt8(ascii: "0")...UInt8(ascii: "9")).contains($0) }), let port = Int(digits) else {
            return nil
        }
        return .some(port)
    }

    private static func _validate(user: String?, password: String?, host: String?, path: String, query: String?, fragment: String?) -> Bool {
        if let user = user, !_isValidPercentEncoded(user, allowed: _URLComponentAllowed.user) { return false }
        if let password = password, !_isValidPercentEncoded(password, allowed: _URLComponentAllowed.password) { return false }
        if let host = host, !_isValidPercentEncoded(host, allowed: _URLComponentAllowed.host) { return false }
        if !_isValidPercentEncoded(path, allowed: _URLComponentAllowed.path.union([UInt8(ascii: ";")])) { return false }
        if let query = query, !_isValidPercentEncoded(query, allowed: _URLComponentAllowed.query) { return false }
        if let fragment = fragment, !_isValidPercentEncoded(fragment, allowed: _URLComponentAllowed.fragment) { return false }
        return true
    }

    private var _hasAuthority: Bool {
        return _user != nil || _password != nil || _host != nil || _port != nil
    }

    /// A URL string created from the components, or nil if the components can't form a valid URL (an authority with
    /// a path that doesn't start with "/", or no authority with a path starting with "//").
    public var string: String? {
        if _hasAuthority && !_path.isEmpty && !_path.hasPrefix("/") { return nil }
        if !_hasAuthority && _path.hasPrefix("//") { return nil }
        var result = ""
        if let scheme = _scheme { result += scheme + ":" }
        if _hasAuthority {
            result += "//"
            if _user != nil || _password != nil {
                result += _user ?? ""
                if let password = _password { result += ":" + password }
                result += "@"
            }
            result += _host ?? ""
            if let port = _port { result += ":" + String(port) }
        }
        result += _path
        if let query = _query { result += "?" + query }
        if let fragment = _fragment { result += "#" + fragment }
        return result
    }

    /// A URL created from the components, or nil if they can't form a valid URL.
    public var url: URL? {
        guard let string = string else { return nil }
        return URL(string: string)
    }

    /// A URL created from the components relative to a base URL, or nil if they can't form a valid URL.
    public func url(relativeTo base: URL?) -> URL? {
        guard let string = string else { return nil }
        return URL(string: string, relativeTo: base)
    }

    /// The scheme subcomponent. Setting an invalid scheme is a programming error.
    public var scheme: String? {
        get { return _scheme }
        set {
            if let s = newValue {
                precondition(!s.isEmpty && s.utf8.allSatisfy({ _URLComponentAllowed.scheme.contains($0) }) &&
                             (UInt8(ascii: "a")...UInt8(ascii: "z")).contains(s.utf8.first! | 0x20),
                             "invalid characters in scheme")
            }
            _scheme = newValue
        }
    }

    /// The user subcomponent, without percent encoding.
    public var user: String? {
        get { return _user.flatMap(_percentDecode) }
        set { _user = newValue.map { _percentEncode($0, allowed: _URLComponentAllowed.user) } }
    }

    /// The password subcomponent, without percent encoding.
    public var password: String? {
        get { return _password.flatMap(_percentDecode) }
        set { _password = newValue.map { _percentEncode($0, allowed: _URLComponentAllowed.password) } }
    }

    /// The host subcomponent, without percent encoding.
    public var host: String? {
        get { return _host.flatMap(_percentDecode) }
        set { _host = newValue.map { _percentEncode($0, allowed: _URLComponentAllowed.host) } }
    }

    /// The port subcomponent. Setting a negative port is a programming error.
    public var port: Int? {
        get { return _port }
        set {
            precondition(newValue.map { $0 >= 0 } ?? true, "negative port number")
            _port = newValue
        }
    }

    /// The path subcomponent, without percent encoding.
    public var path: String {
        get { return _percentDecode(_path) ?? _path }
        set { _path = _percentEncode(newValue, allowed: _URLComponentAllowed.path) }
    }

    /// The query subcomponent, without percent encoding.
    public var query: String? {
        get { return _query.flatMap(_percentDecode) }
        set { _query = newValue.map { _percentEncode($0, allowed: _URLComponentAllowed.query) } }
    }

    /// The fragment subcomponent, without percent encoding.
    public var fragment: String? {
        get { return _fragment.flatMap(_percentDecode) }
        set { _fragment = newValue.map { _percentEncode($0, allowed: _URLComponentAllowed.fragment) } }
    }

    private static func _setPercentEncoded(_ value: String?, allowed: Set<UInt8>, _ name: String) -> String? {
        if let value = value {
            precondition(_isValidPercentEncoded(value, allowed: allowed), "invalid characters in percent-encoded \(name)")
        }
        return value
    }

    /// The user subcomponent, percent-encoded.
    public var percentEncodedUser: String? {
        get { return _user }
        set { _user = Self._setPercentEncoded(newValue, allowed: _URLComponentAllowed.user, "user") }
    }

    /// The password subcomponent, percent-encoded.
    public var percentEncodedPassword: String? {
        get { return _password }
        set { _password = Self._setPercentEncoded(newValue, allowed: _URLComponentAllowed.password, "password") }
    }

    /// The host subcomponent, percent-encoded.
    public var percentEncodedHost: String? {
        get { return _host }
        set { _host = Self._setPercentEncoded(newValue, allowed: _URLComponentAllowed.host, "host") }
    }

    /// The path subcomponent, percent-encoded.
    public var percentEncodedPath: String {
        get { return _path }
        set { _path = Self._setPercentEncoded(newValue, allowed: _URLComponentAllowed.path.union([UInt8(ascii: ";")]), "path") ?? "" }
    }

    /// The query subcomponent, percent-encoded.
    public var percentEncodedQuery: String? {
        get { return _query }
        set { _query = Self._setPercentEncoded(newValue, allowed: _URLComponentAllowed.query, "query") }
    }

    /// The fragment subcomponent, percent-encoded.
    public var percentEncodedFragment: String? {
        get { return _fragment }
        set { _fragment = Self._setPercentEncoded(newValue, allowed: _URLComponentAllowed.fragment, "fragment") }
    }

    private static func _splitQuery(_ query: String, decode: Bool) -> [URLQueryItem] {
        // An empty query has no items (not one item with an empty name).
        guard !query.isEmpty else { return [] }
        return query.split(separator: "&", omittingEmptySubsequences: false).map { pair in
            let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            let rawName = String(parts[0])
            let rawValue = parts.count > 1 ? String(parts[1]) : nil
            if decode {
                return URLQueryItem(name: _percentDecode(rawName) ?? rawName, value: rawValue.map { _percentDecode($0) ?? $0 })
            }
            return URLQueryItem(name: rawName, value: rawValue)
        }
    }

    /// The query items, in order, without percent encoding. nil if there is no query; empty if the query is empty.
    ///
    /// The setter percent-encodes names and values; `&` and `=` in names and `&` in values are encoded so the
    /// items survive a round trip.
    public var queryItems: [URLQueryItem]? {
        get { return _query.map { Self._splitQuery($0, decode: true) } }
        set {
            _query = newValue.map { items in
                let nameAllowed = _URLComponentAllowed.query.subtracting("&=".utf8)
                let valueAllowed = _URLComponentAllowed.query.subtracting("&".utf8)
                return items.map { item in
                    let name = _percentEncode(item.name, allowed: nameAllowed)
                    guard let value = item.value else { return name }
                    return name + "=" + _percentEncode(value, allowed: valueAllowed)
                }.joined(separator: "&")
            }
        }
    }

    /// The query items, in order, with any percent encoding retained.
    public var percentEncodedQueryItems: [URLQueryItem]? {
        get { return _query.map { Self._splitQuery($0, decode: false) } }
        set {
            _query = newValue.map { items in
                items.map { item in
                    precondition(_isValidPercentEncoded(item.name, allowed: _URLComponentAllowed.query.subtracting("&=".utf8)) &&
                                 (item.value.map { _isValidPercentEncoded($0, allowed: _URLComponentAllowed.query.subtracting("&".utf8)) } ?? true),
                                 "invalid characters in percent-encoded query item")
                    return item.value.map { item.name + "=" + $0 } ?? item.name
                }.joined(separator: "&")
            }
        }
    }
}

extension URLComponents : CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public var description: String {
        if let u = url {
            return u.description
        } else {
            return self.customMirror.children.reduce("") {
                $0 + "\($1.label ?? ""): \($1.value) "
            }
        }
    }

    public var debugDescription: String {
        return self.description
    }

    public var customMirror: Mirror {
        var c: [(label: String?, value: Any)] = []
        if let s = self.scheme { c.append((label: "scheme", value: s)) }
        if let u = self.user { c.append((label: "user", value: u)) }
        if let pw = self.password { c.append((label: "password", value: pw)) }
        if let h = self.host { c.append((label: "host", value: h)) }
        if let p = self.port { c.append((label: "port", value: p)) }
        c.append((label: "path", value: self.path))
        if let qi = self.queryItems { c.append((label: "queryItems", value: qi)) }
        if let f = self.fragment { c.append((label: "fragment", value: f)) }
        return Mirror(self, children: c, displayStyle: Mirror.DisplayStyle.struct)
    }
}

extension URLComponents : Codable {
    private enum CodingKeys : Int, CodingKey {
        case scheme
        case user
        case password
        case host
        case port
        case path
        case query
        case fragment
    }

    public init(from decoder: Decoder) throws {
        self.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.scheme = try container.decodeIfPresent(String.self, forKey: .scheme)
        self.user = try container.decodeIfPresent(String.self, forKey: .user)
        self.password = try container.decodeIfPresent(String.self, forKey: .password)
        self.host = try container.decodeIfPresent(String.self, forKey: .host)
        self.port = try container.decodeIfPresent(Int.self, forKey: .port)
        self.path = try container.decode(String.self, forKey: .path)
        self.query = try container.decodeIfPresent(String.self, forKey: .query)
        self.fragment = try container.decodeIfPresent(String.self, forKey: .fragment)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.scheme, forKey: .scheme)
        try container.encodeIfPresent(self.user, forKey: .user)
        try container.encodeIfPresent(self.password, forKey: .password)
        try container.encodeIfPresent(self.host, forKey: .host)
        try container.encodeIfPresent(self.port, forKey: .port)
        try container.encode(self.path, forKey: .path)
        try container.encodeIfPresent(self.query, forKey: .query)
        try container.encodeIfPresent(self.fragment, forKey: .fragment)
    }
}

/// A single name-value pair, for use with `URLComponents`.
public struct URLQueryItem : Hashable, Equatable {
    /// The name of the query item.
    public var name: String

    /// The value of the query item, or nil if the item has no `=`.
    public var value: String?

    public init(name: __shared String, value: __shared String?) {
        self.name = name
        self.value = value
    }
}

extension URLQueryItem : CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public var description: String {
        if let v = value {
            return "\(name)=\(v)"
        } else {
            return name
        }
    }

    public var debugDescription: String {
        return self.description
    }

    public var customMirror: Mirror {
        let c: [(label: String?, value: Any)] = [
          ("name", name),
          ("value", value as Any),
        ]
        return Mirror(self, children: c, displayStyle: Mirror.DisplayStyle.struct)
    }
}
