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

// URL, from release/5.4 stdlib/public/Darwin/Foundation/URL.swift.
// Darling: NSURL's accessors are methods returning implicitly unwrapped values, resource values, bookmarks and
// promised items are omitted (Darling's NSURL doesn't implement them), and the path-appending API from newer SDKs
// (DirectoryHint, appending(path:directoryHint:), appending(component:directoryHint:), path(percentEncoded:)) is
// written on top of the NSURL methods and CFURL functions.

@_exported import Foundation // Clang module

public struct URL : ReferenceConvertible, Equatable {
    public typealias ReferenceType = NSURL
    private var _url: NSURL

    /// Initialize with string.
    ///
    /// Returns `nil` if a `URL` cannot be formed with the string (for example, if the string contains characters that are illegal in a URL, or is an empty string).
    public init?(string: __shared String) {
        guard !string.isEmpty, let inner = NSURL(string: string) else { return nil }
        _url = URL._converted(from: inner)
    }

    /// Initialize with string, relative to another URL.
    ///
    /// Returns `nil` if a `URL` cannot be formed with the string (for example, if the string contains characters that are illegal in a URL, or is an empty string).
    public init?(string: __shared String, relativeTo url: __shared URL?) {
        guard !string.isEmpty, let inner = NSURL(string: string, relativeTo: url) else { return nil }
        _url = URL._converted(from: inner)
    }

    /// Initializes a newly created file URL referencing the local file or directory at path.
    ///
    /// If an empty string is used for the path, then the path is assumed to be ".".
    /// - note: This function avoids an extra file system access to check if the file URL is a directory. You should use it if you know the answer already.
    public init(fileURLWithPath path: __shared String, isDirectory: Bool) {
        _url = URL._converted(from: NSURL(fileURLWithPath: path.isEmpty ? "." : path, isDirectory: isDirectory))
    }

    /// Initializes a newly created file URL referencing the local file or directory at path.
    ///
    /// If an empty string is used for the path, then the path is assumed to be ".".
    public init(fileURLWithPath path: __shared String) {
        _url = URL._converted(from: NSURL(fileURLWithPath: path.isEmpty ? "." : path))
    }

    /// Initializes a newly created file URL referencing the local file or directory at path, relative to a base URL.
    ///
    /// If an empty string is used for the path, then the path is assumed to be ".".
    public init(fileURLWithPath path: __shared String, relativeTo base: __shared URL?) {
        let p = path.isEmpty ? "." : path
        if let base = base, !p.hasPrefix("/") {
            // Not NSURL(string:relativeTo:): spaces, % and #/? in a file name must stay part of the path.
            func fileURL(isDirectory: Bool) -> NSURL {
                return p.withCString {
                    NSURL.fileURL(withFileSystemRepresentation: $0, isDirectory: isDirectory, relativeTo: base)
                } as! NSURL
            }
            var relative = fileURL(isDirectory: p.hasSuffix("/"))
            // Like -initFileURLWithPath:relativeToURL:, ask the file system when there's no trailing slash.
            var info = stat()
            if !p.hasSuffix("/"), stat(relative.fileSystemRepresentation(), &info) == 0, info.st_mode & S_IFMT == S_IFDIR {
                relative = fileURL(isDirectory: true)
            }
            _url = URL._converted(from: relative)
        } else {
            _url = URL._converted(from: NSURL(fileURLWithPath: p))
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_url)
    }

    /// Returns the absolute string for the URL.
    public var absoluteString: String {
        if let string = _url.absoluteString() {
            return string
        } else {
            // This should never fail for non-file reference URLs
            return ""
        }
    }

    /// The relative portion of a URL.
    ///
    /// If `baseURL` is nil, or if the receiver is itself absolute, this is the same as `absoluteString`.
    public var relativeString: String {
        return _url.relativeString() ?? ""
    }

    /// Returns the base URL.
    ///
    /// If the URL is itself absolute, then this value is nil.
    public var baseURL: URL? {
        return _url.base()
    }

    /// Returns the absolute URL.
    ///
    /// If the URL is itself absolute, this will return self.
    public var absoluteURL: URL {
        if let url = _url.absolute() {
            return url
        } else {
            // This should never fail for non-file reference URLs
            return self
        }
    }

    /// Returns the scheme of the URL.
    public var scheme: String? {
        return _url.scheme()
    }

    /// Returns true if the scheme is `file:`.
    public var isFileURL: Bool {
        return _url.isFileURL()
    }

    /// If the URL conforms to RFC 1808 (the most common form of URL), returns the host component of the URL; otherwise it returns nil.
    public var host: String? {
        return _url.host()
    }

    /// If the URL conforms to RFC 1808 (the most common form of URL), returns the port component of the URL; otherwise it returns nil.
    public var port: Int? {
        return _url.port()?.integerValue()
    }

    /// If the URL conforms to RFC 1808 (the most common form of URL), returns the user component of the URL; otherwise it returns nil.
    public var user: String? {
        return _url.user()
    }

    /// If the URL conforms to RFC 1808 (the most common form of URL), returns the password component of the URL; otherwise it returns nil.
    public var password: String? {
        return _url.password()
    }

    /// If the URL conforms to RFC 1808 (the most common form of URL), returns the path component of the URL; otherwise it returns an empty string.
    ///
    /// If the URL contains a parameter string, it is appended to the path with a `;`.
    public var path: String {
        if let parameterString = _url.parameterString() {
            if let path = _url.path() {
                return path + ";" + parameterString
            } else {
                return ";" + parameterString
            }
        } else if let path = _url.path() {
            return path
        } else {
            return ""
        }
    }

    /// If the URL conforms to RFC 1808 (the most common form of URL), returns the relative path of the URL; otherwise it returns nil.
    ///
    /// This is the same as path if baseURL is nil.
    public var relativePath: String {
        if let parameterString = _url.parameterString() {
            if let path = _url.relativePath() {
                return path + ";" + parameterString
            } else {
                return ";" + parameterString
            }
        } else if let path = _url.relativePath() {
            return path
        } else {
            return ""
        }
    }

    /// Returns the path of the URL, optionally percent-encoded (macOS 13+ API).
    public func path(percentEncoded: Bool = true) -> String {
        // CFURLCopyPath keeps the trailing slash and the URL's own percent-encoding, which -[NSURL path] drops.
        let absolute = unsafeBitCast(_url.absolute().map { $0 as NSURL } ?? _url, to: CFURL.self)
        var encoded = CFURLCopyPath(absolute).map { $0 as String } ?? ""
        if let parameterString = CFURLCopyParameterString(absolute, nil) {
            encoded += ";" + (parameterString as String)
        }
        guard !percentEncoded else { return encoded }
        return CFURLCreateStringByReplacingPercentEscapes(nil, encoded as CFString, "" as CFString).map { $0 as String } ?? ""
    }

    /// If the URL conforms to RFC 1808 (the most common form of URL), returns the fragment component of the URL; otherwise it returns nil.
    public var fragment: String? {
        return _url.fragment()
    }

    /// If the URL conforms to RFC 1808 (the most common form of URL), returns the query of the URL; otherwise it returns nil.
    public var query: String? {
        return _url.query()
    }

    /// Returns true if the URL path represents a directory.
    public var hasDirectoryPath: Bool {
        // -[NSURL path] drops the trailing slash; Darling's NSURL is toll-free bridged to CFURL.
        return CFURLHasDirectoryPath(unsafeBitCast(_url, to: CFURL.self))
    }

    /// Passes the URL's path in file system representation to `block`.
    ///
    /// File system representation is a null-terminated C string with canonical UTF-8 encoding.
    /// - note: The pointer is not valid outside the context of the block.
    public func withUnsafeFileSystemRepresentation<ResultType>(_ block: (UnsafePointer<Int8>?) throws -> ResultType) rethrows -> ResultType {
        return try block(_url.fileSystemRepresentation())
    }

    // MARK: -
    // MARK: Path manipulation

    /// Returns the path components of the URL, or an empty array if the path is an empty string.
    public var pathComponents: [String] {
        // In accordance with our above change to never return a nil path, here we return an empty array.
        return (_url.pathComponents() as? [String]) ?? []
    }

    /// Returns the last path component of the URL, or an empty string if the path is an empty string.
    public var lastPathComponent: String {
        return _url.lastPathComponent() ?? ""
    }

    /// Returns the path extension of the URL, or an empty string if the path is an empty string.
    public var pathExtension: String {
        return _url.pathExtension() ?? ""
    }

    /// Returns a URL constructed by appending the given path component to self.
    ///
    /// - parameter pathComponent: The path component to add.
    /// - parameter isDirectory: If `true`, then a trailing `/` is added to the resulting path.
    public func appendingPathComponent(_ pathComponent: String, isDirectory: Bool) -> URL {
        if let result = _url.appendingPathComponent(pathComponent, isDirectory: isDirectory) {
            return result
        } else {
            return self
        }
    }

    /// Returns a URL constructed by appending the given path component to self.
    ///
    /// - parameter pathComponent: The path component to add.
    public func appendingPathComponent(_ pathComponent: String) -> URL {
        if let result = _url.appendingPathComponent(pathComponent) {
            return result
        } else {
            return self
        }
    }

    /// Returns a URL constructed by removing the last path component of self.
    ///
    /// This function may either remove a path component or append `/..`.
    ///
    /// If the URL has an empty path (e.g., `http://www.example.com`), then this function will return the URL unchanged.
    public func deletingLastPathComponent() -> URL {
        // This is a slight behavior change from NSURL, but better than returning "http://www.example.com../".
        guard !path.isEmpty, let result = _url.deletingLastPathComponent() else { return self }
        return result
    }

    /// Returns a URL constructed by appending the given path extension to self.
    ///
    /// If the URL has an empty path (e.g., `http://www.example.com`), then this function will return the URL unchanged.
    public func appendingPathExtension(_ pathExtension: String) -> URL {
        guard !path.isEmpty, let result = _url.appendingPathExtension(pathExtension) else { return self }
        return result
    }

    /// Returns a URL constructed by removing any path extension.
    ///
    /// If the URL has an empty path (e.g., `http://www.example.com`), then this function will return the URL unchanged.
    public func deletingPathExtension() -> URL {
        guard !path.isEmpty, let result = _url.deletingPathExtension() else { return self }
        return result
    }

    /// Appends a path component to the URL.
    ///
    /// - parameter pathComponent: The path component to add.
    /// - parameter isDirectory: Use `true` if the resulting path is a directory.
    public mutating func appendPathComponent(_ pathComponent: String, isDirectory: Bool) {
        self = appendingPathComponent(pathComponent, isDirectory: isDirectory)
    }

    /// Appends a path component to the URL.
    ///
    /// - parameter pathComponent: The path component to add.
    public mutating func appendPathComponent(_ pathComponent: String) {
        self = appendingPathComponent(pathComponent)
    }

    /// Appends the given path extension to self.
    ///
    /// If the URL has an empty path (e.g., `http://www.example.com`), then this function will do nothing.
    public mutating func appendPathExtension(_ pathExtension: String) {
        self = appendingPathExtension(pathExtension)
    }

    /// Returns a URL constructed by removing the last path component of self.
    ///
    /// If the URL has an empty path (e.g., `http://www.example.com`), then this function will do nothing.
    public mutating func deleteLastPathComponent() {
        self = deletingLastPathComponent()
    }

    /// Returns a URL constructed by removing any path extension.
    ///
    /// If the URL has an empty path (e.g., `http://www.example.com`), then this function will do nothing.
    public mutating func deletePathExtension() {
        self = deletingPathExtension()
    }

    /// Returns a `URL` with any instances of ".." or "." removed from its path.
    public var standardized : URL {
        guard let result = _url.standardized() else { return self }
        return result
    }

    /// Standardizes the path of a file URL.
    ///
    /// If the `isFileURL` is false, this method does nothing.
    public mutating func standardize() {
        self = self.standardized
    }

    /// Standardizes the path of a file URL. Non-file URLs are unchanged.
    public var standardizedFileURL: URL {
        guard isFileURL, let result = _url.standardizingPath() else { return self }
        return result
    }

    /// Resolves symbolic links in the path of a file URL. Non-file URLs are unchanged.
    public func resolvingSymlinksInPath() -> URL {
        guard isFileURL, let result = _url.resolvingSymlinksInPath() else { return self }
        return result
    }

    // MARK: - Reachability

    /// Returns whether the URL's resource exists and is reachable.
    public func checkResourceIsReachable() throws -> Bool {
        // -checkResourceIsReachableAndReturnError: imports as a throwing method.
        try _url.checkResourceIsReachable()
        return true
    }

    // MARK: - Security scope

    /// Given an instance of `URL` created from a security scoped bookmark, make the resource referenced by the url accessible to the process.
    public func startAccessingSecurityScopedResource() -> Bool {
        return _url.startAccessingSecurityScopedResource()
    }

    /// Revokes the access granted to the url by a prior successful call to startAccessingSecurityScopedResource().
    public func stopAccessingSecurityScopedResource() {
        _url.stopAccessingSecurityScopedResource()
    }

    // MARK: - Bridging Support

    /// We must not store an NSURL without running it through this function. This makes sure that we do not hold a file reference URL, which changes the nullability of many NSURL functions.
    private static func _converted(from url: NSURL) -> NSURL {
        return url
    }

    fileprivate init(reference: __shared NSURL) {
        _url = URL._converted(from: reference).copy() as! NSURL
    }

    private var reference: NSURL {
        return _url
    }

    public static func ==(lhs: URL, rhs: URL) -> Bool {
        return lhs.reference.isEqual(rhs.reference)
    }
}

// MARK: - Path appending with directory hints (macOS 13+ API)

extension URL {
    /// A hint about whether a path refers to a directory.
    public enum DirectoryHint {
        /// The path is a directory; a trailing `/` is added.
        case isDirectory
        /// The path isn't a directory.
        case notDirectory
        /// Infer from the path: a trailing `/` means a directory.
        case inferFromPath
        /// Check the file system (treated like `inferFromPath` here).
        case checkFileSystem
    }

    private func _appending(_ component: String, hint: DirectoryHint) -> URL {
        switch hint {
        case .isDirectory:
            return appendingPathComponent(component, isDirectory: true)
        case .notDirectory:
            return appendingPathComponent(component, isDirectory: false)
        case .inferFromPath, .checkFileSystem:
            return appendingPathComponent(component, isDirectory: component.hasSuffix("/"))
        }
    }

    /// Returns a URL by appending a path, which may contain several components.
    public func appending<S: StringProtocol>(path: S, directoryHint: DirectoryHint = .inferFromPath) -> URL {
        return _appending(String(path), hint: directoryHint)
    }

    /// Returns a URL by appending a single path component.
    public func appending<S: StringProtocol>(component: S, directoryHint: DirectoryHint = .inferFromPath) -> URL {
        return _appending(String(component), hint: directoryHint)
    }

    /// Returns a URL by appending path components.
    public func appending<S: StringProtocol>(components: S..., directoryHint: DirectoryHint = .inferFromPath) -> URL {
        var result = self
        for (i, component) in components.enumerated() {
            result = result._appending(String(component), hint: i == components.count - 1 ? directoryHint : .isDirectory)
        }
        return result
    }

    /// Appends a path, which may contain several components.
    public mutating func append<S: StringProtocol>(path: S, directoryHint: DirectoryHint = .inferFromPath) {
        self = appending(path: path, directoryHint: directoryHint)
    }

    /// Appends a single path component.
    public mutating func append<S: StringProtocol>(component: S, directoryHint: DirectoryHint = .inferFromPath) {
        self = appending(component: component, directoryHint: directoryHint)
    }
}

extension URL : _ObjectiveCBridgeable {
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSURL {
        return _url
    }

    public static func _forceBridgeFromObjectiveC(_ source: NSURL, result: inout URL?) {
        if !_conditionallyBridgeFromObjectiveC(source, result: &result) {
            fatalError("Unable to bridge \(_ObjectiveCType.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ source: NSURL, result: inout URL?) -> Bool {
        result = URL(reference: source)
        return true
    }

    @_effects(readonly)
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSURL?) -> URL {
        var result: URL?
        _forceBridgeFromObjectiveC(source!, result: &result)
        return result!
    }
}

extension URL : CustomStringConvertible, CustomDebugStringConvertible {
    // Darling: NSURL's -description clashes with +description in Swift, so build NSURL's format here.
    public var description: String {
        if let base = baseURL {
            return relativeString + " -- " + base.description
        }
        return absoluteString
    }

    public var debugDescription: String {
        return description
    }
}

extension NSURL : _HasCustomAnyHashableRepresentation {
    // Must be @nonobjc to avoid infinite recursion during bridging.
    @nonobjc
    public func _toCustomAnyHashable() -> AnyHashable? {
        return AnyHashable(self as URL)
    }
}

extension URL : Codable {
    private enum CodingKeys : Int, CodingKey {
        case base
        case relative
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let relative = try container.decode(String.self, forKey: .relative)
        let base = try container.decodeIfPresent(URL.self, forKey: .base)

        guard let url = URL(string: relative, relativeTo: base) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                    debugDescription: "Invalid URL string."))
        }

        self = url
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.relativeString, forKey: .relative)
        if let base = self.baseURL {
            try container.encode(base, forKey: .base)
        }
    }
}

// MARK: - Members from release/5.4 (apple/swift 845205b4407c) stdlib/public/Darwin/Foundation/URL.swift that were
// missing here: bookmarks, alias files, resource values, promised items, data representation, file references.
// Darling: adapted to Darling's NSURL accessors, which are methods.

extension URL {
    public typealias BookmarkResolutionOptions = NSURLBookmarkResolutionOptions
    public typealias BookmarkCreationOptions = NSURLBookmarkCreationOptions

    /// Initializes a newly created file URL referencing the local file or directory at path, relative to a base URL.
    ///
    /// If an empty string is used for the path, then the path is assumed to be ".".
    /// - note: This function avoids an extra file system access to check if the file URL is a directory. You should use it if you know the answer already.
    @available(macOS 10.11, iOS 9.0, *)
    public init(fileURLWithPath path: __shared String, isDirectory: Bool, relativeTo base: __shared URL?) {
        _url = URL._converted(from: NSURL(fileURLWithPath: path.isEmpty ? "." : path, isDirectory: isDirectory, relativeTo: base))
    }

    /// Initializes a newly created URL using the contents of the given data, relative to a base URL.
    ///
    /// If the data representation is not a legal URL string as ASCII bytes, the URL object may not behave as expected. If the URL cannot be formed then this will return nil.
    @available(macOS 10.11, iOS 9.0, *)
    

    /// Initializes a URL that refers to a location specified by resolving bookmark data.
    @available(swift, obsoleted: 4.2)
    public init?(resolvingBookmarkData data: __shared Data, options: BookmarkResolutionOptions = [], relativeTo url: __shared URL? = nil, bookmarkDataIsStale: inout Bool) throws {
        var stale : ObjCBool = false
        _url = URL._converted(from: try NSURL(byResolvingBookmarkData: data, options: options, relativeTo: url, bookmarkDataIsStale: &stale))
        bookmarkDataIsStale = stale.boolValue
    }

    /// Initializes a URL that refers to a location specified by resolving bookmark data.
    @available(swift, introduced: 4.2)
    public init(resolvingBookmarkData data: __shared Data, options: BookmarkResolutionOptions = [], relativeTo url: __shared URL? = nil, bookmarkDataIsStale: inout Bool) throws {
        var stale : ObjCBool = false
        _url = URL._converted(from: try NSURL(byResolvingBookmarkData: data, options: options, relativeTo: url, bookmarkDataIsStale: &stale))
        bookmarkDataIsStale = stale.boolValue
    }

    /// Creates and initializes an NSURL that refers to the location specified by resolving the alias file at url. If the url argument does not refer to an alias file as defined by the NSURLIsAliasFileKey property, the NSURL returned is the same as url argument. This method fails and returns nil if the url argument is unreachable, or if the original file or directory could not be located or is not reachable, or if the original file or directory is on a volume that could not be located or mounted. The URLBookmarkResolutionWithSecurityScope option is not supported by this method.
    @available(macOS 10.10, iOS 8.0, *)
    

    /// Initializes a newly created URL referencing the local file or directory at the file system representation of the path. File system representation is a null-terminated C string with canonical UTF-8 encoding.
    public init(fileURLWithFileSystemRepresentation path: UnsafePointer<Int8>, isDirectory: Bool, relativeTo baseURL: __shared URL?) {
        _url = URL._converted(from: NSURL.fileURL(withFileSystemRepresentation: path, isDirectory: isDirectory, relativeTo: baseURL) as! NSURL)
    }

    /// Returns the data representation of the URL's relativeString. 
    ///
    /// If the URL was initialized with `init?(dataRepresentation:relativeTo:isAbsolute:)`, the data representation returned are the same bytes as those used at initialization; otherwise, the data representation returned are the bytes of the `relativeString` encoded with UTF8 string encoding.
    @available(macOS 10.11, iOS 9.0, *)
    

    /// Resolves any symlinks in the path of a file URL.
    ///
    /// If the `isFileURL` is false, this method does nothing.
    public mutating func resolveSymlinksInPath() {
        self = self.resolvingSymlinksInPath()
    }

    /// Returns whether the promised item URL's resource exists and is reachable.
    ///
    /// This method synchronously checks if the resource's backing store is reachable. Checking reachability is appropriate when making decisions that do not require other immediate operations on the resource, e.g. periodic maintenance of UI state that depends on the existence of a specific document. When performing operations such as opening a file or copying resource properties, it is more efficient to simply try the operation and handle failures. This method is currently applicable only to URLs for file system resources. For other URL types, `false` is returned.
    @available(macOS 10.10, iOS 8.0, *)
    

    /// Sets the resource value identified by a given resource key.
    /// 
    /// This method writes the new resource values out to the backing store. Attempts to set a read-only resource property or to set a resource property not supported by the resource are ignored and are not considered errors. This method is currently applicable only to URLs for file system resources.
    ///
    /// `URLResourceValues` keeps track of which of its properties have been set. Those values are the ones used by this function to determine which properties to write.
    public mutating func setResourceValues(_ values: URLResourceValues) throws {
        try _url.setResourceValues(values.allValues)
    }

    /// Return a collection of resource values identified by the given resource keys.
    ///
    /// This method first checks if the URL object already caches the resource value. If so, it returns the cached resource value to the caller. If not, then this method synchronously obtains the resource value from the backing store, adds the resource value to the URL object's cache, and returns the resource value to the caller. The type of the resource value varies by resource property (see resource key definitions). If this method does not throw and the resulting value in the `URLResourceValues` is populated with nil, it means the resource property is not available for the specified resource and no errors occurred when determining the resource property was not available. This method is currently applicable only to URLs for file system resources.
    ///
    /// When this function is used from the main thread, resource values cached by the URL (except those added as temporary properties) are removed the next time the main thread's run loop runs. `func removeCachedResourceValue(forKey:)` and `func removeAllCachedResourceValues()` also may be used to remove cached resource values.
    ///
    /// Only the values for the keys specified in `keys` will be populated.
    public func resourceValues(forKeys keys: Set<URLResourceKey>) throws -> URLResourceValues {
        let raw = try _url.resourceValues(forKeys: keys.map { $0.rawValue })
        var values: [URLResourceKey: Any] = [:]
        for (key, value) in raw {
            if let name = key as? String {
                values[URLResourceKey(rawValue: name)] = value
            }
        }
        return URLResourceValues(keys: keys, values: values)
    }

    /// Sets a temporary resource value on the URL object.
    ///
    /// Temporary resource values are for client use. Temporary resource values exist only in memory and are never written to the resource's backing store. Once set, a temporary resource value can be copied from the URL object with `func resourceValues(forKeys:)`. The values are stored in the loosely-typed `allValues` dictionary property.
    ///
    /// To remove a temporary resource value from the URL object, use `func removeCachedResourceValue(forKey:)`. Care should be taken to ensure the key that identifies a temporary resource value is unique and does not conflict with system defined keys (using reverse domain name notation in your temporary resource value keys is recommended). This method is currently applicable only to URLs for file system resources.
    

    /// Removes all cached resource values and all temporary resource values from the URL object.
    /// 
    /// This method is currently applicable only to URLs for file system resources.
    

    /// Removes the cached resource value identified by a given resource value key from the URL object.
    /// 
    /// Removing a cached resource value may remove other cached resource values because some resource values are cached as a set of values, and because some resource values depend on other resource values (temporary resource values have no dependencies). This method is currently applicable only to URLs for file system resources.
    

    /// Get resource values from URLs of 'promised' items.
    ///
    /// A promised item is not guaranteed to have its contents in the file system until you use `FileCoordinator` to perform a coordinated read on its URL, which causes the contents to be downloaded or otherwise generated. Promised item URLs are returned by various APIs, including currently:
    ///     NSMetadataQueryUbiquitousDataScope
    ///     NSMetadataQueryUbiquitousDocumentsScope
    ///     A `FilePresenter` presenting the contents of the directory located by -URLForUbiquitousContainerIdentifier: or a subdirectory thereof
    ///
    /// The following methods behave identically to their similarly named methods above (`func resourceValues(forKeys:)`, etc.), except that they allow you to get resource values and check for presence regardless of whether the promised item's contents currently exist at the URL. You must use these APIs instead of the normal URL resource value APIs if and only if any of the following are true:
    ///     You are using a URL that you know came directly from one of the above APIs
    ///     You are inside the accessor block of a coordinated read or write that used NSFileCoordinatorReadingImmediatelyAvailableMetadataOnly, NSFileCoordinatorWritingForDeleting, NSFileCoordinatorWritingForMoving, or NSFileCoordinatorWritingContentIndependentMetadataOnly
    ///
    /// Most of the URL resource value keys will work with these APIs. However, there are some that are tied to the item's contents that will not work, such as `contentAccessDateKey` or `generationIdentifierKey`. If one of these keys is used, the method will return a `URLResourceValues` value, but the value for that property will be nil.
    @available(macOS 10.10, iOS 8.0, *)
    

    @available(*, unavailable, message: "Use struct URLResourceValues and URL.setResourceValues(_:) instead")
    public func setResourceValue(_ value: AnyObject?, forKey key: URLResourceKey) throws {
        fatalError()
    }

    @available(*, unavailable, message: "Use struct URLResourceValues and URL.setResourceValues(_:) instead")
    public func setResourceValues(_ keyedValues: [URLResourceKey : AnyObject]) throws {
        fatalError()
    }

    @available(*, unavailable, message: "Use struct URLResourceValues and URL.setResourceValues(_:) instead")
    public func getResourceValue(_ value: AutoreleasingUnsafeMutablePointer<AnyObject?>, forKey key: URLResourceKey) throws {
        fatalError()
    }

    /// Returns bookmark data for the URL, created with specified options and resource values.
    public func bookmarkData(options: BookmarkCreationOptions = [], includingResourceValuesForKeys keys: Set<URLResourceKey>? = nil, relativeTo url: URL? = nil) throws -> Data {
        let result = try _url.bookmarkData(options: options, includingResourceValuesForKeys: keys.flatMap { Array($0) }, relativeTo: url)
        return result
    }

    /// Returns the resource values for properties identified by a specified array of keys contained in specified bookmark data. If the result dictionary does not contain a resource value for one or more of the requested resource keys, it means those resource properties are not available in the bookmark data.
    public static func resourceValues(forKeys keys: Set<URLResourceKey>, fromBookmarkData data: Data) -> URLResourceValues? {
        guard let raw = NSURL.resourceValues(forKeys: keys.map { $0.rawValue }, fromBookmarkData: data) else { return nil }
        var values: [URLResourceKey: Any] = [:]
        for (key, value) in raw {
            if let name = key as? String {
                values[URLResourceKey(rawValue: name)] = value
            }
        }
        return URLResourceValues(keys: keys, values: values)
    }

    /// Creates an alias file on disk at a specified location with specified bookmark data. bookmarkData must have been created with the URLBookmarkCreationSuitableForBookmarkFile option. bookmarkFileURL must either refer to an existing file (which will be overwritten), or to location in an existing directory.
    public static func writeBookmarkData(_ data : Data, to url: URL) throws {
        // Options are unused
        try NSURL.writeBookmarkData(data, to: url, options: 0)
    }

    /// Initializes and returns bookmark data derived from an alias file pointed to by a specified URL. If bookmarkFileURL refers to an alias file created prior to OS X v10.6 that contains Alias Manager information but no bookmark data, this method synthesizes bookmark data for the file.
    public static func bookmarkData(withContentsOf url: URL) throws -> Data {
        let result = try NSURL.bookmarkData(withContentsOf: url)
        return result
    }
}

//===----------------------------------------------------------------------===//
// File references, for playgrounds.
//===----------------------------------------------------------------------===//

extension URL : _ExpressibleByFileReferenceLiteral {
  public init(fileReferenceLiteralResourceName name: String) {
    self = Bundle.main.url(forResource: name, withExtension: nil)!
  }
}

public typealias _FileReferenceLiteralType = URL
