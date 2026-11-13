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


// From release/5.4 (apple/swift 845205b4407c) stdlib/public/Darwin/Foundation/URL.swift: URLResourceValues.

@_exported import Foundation // Clang module

public struct URLResourceValues {
    fileprivate var _values: [URLResourceKey: Any]
    fileprivate var _keys: Set<URLResourceKey>
    
    public init() {
        _values = [:]
        _keys = []
    }
    
    init(keys: Set<URLResourceKey>, values: [URLResourceKey: Any]) {
        _values = values
        _keys = keys
    }
    
    private func contains(_ key: URLResourceKey) -> Bool {
        return _keys.contains(key)
    }
    
    private func _get<T>(_ key : URLResourceKey) -> T? {
        return _values[key] as? T
    }
    private func _get(_ key : URLResourceKey) -> Bool? {
        return (_values[key] as? NSNumber)?.boolValue()
    }
    private func _get(_ key: URLResourceKey) -> Int? {
        return (_values[key] as? NSNumber)?.integerValue()
    }
    
    private mutating func _set(_ key : URLResourceKey, newValue : __owned Any?) {
        _keys.insert(key)
        _values[key] = newValue
    }
    private mutating func _set(_ key : URLResourceKey, newValue : String?) {
        _keys.insert(key)
        _values[key] = newValue as NSString?
    }
    private mutating func _set(_ key : URLResourceKey, newValue : [String]?) {
        _keys.insert(key)
        _values[key] = newValue as NSObject?
    }
    private mutating func _set(_ key : URLResourceKey, newValue : Date?) {
        _keys.insert(key)
        _values[key] = newValue as NSDate?
    }
    private mutating func _set(_ key : URLResourceKey, newValue : URL?) {
        _keys.insert(key)
        _values[key] = newValue as NSURL?
    }
    private mutating func _set(_ key : URLResourceKey, newValue : Bool?) {
        _keys.insert(key)
        if let value = newValue {
            _values[key] = NSNumber(value: value)
        } else {
            _values[key] = nil
        }
    }
    private mutating func _set(_ key : URLResourceKey, newValue : Int?) {
        _keys.insert(key)
        if let value = newValue {
            _values[key] = NSNumber(value: value)
        } else {
            _values[key] = nil
        }
    }
    
    /// A loosely-typed dictionary containing all keys and values.
    ///
    /// If you have set temporary keys or non-standard keys, you can find them in here.
    public var allValues : [URLResourceKey : Any] {
        return _values
    }
    
    /// The resource name provided by the file system.
    public var name: String? {
        get { return _get(.nameKey) }
        set { _set(.nameKey, newValue: newValue) }
    }
    
    /// Localized or extension-hidden name as displayed to users.
    public var localizedName: String? { return _get(.localizedNameKey) }
    
    /// True for regular files.
    public var isRegularFile: Bool? { return _get(.isRegularFileKey) }
    
    /// True for directories.
    public var isDirectory: Bool? { return _get(.isDirectoryKey) }
    
    /// True for symlinks.
    public var isSymbolicLink: Bool? { return _get(.isSymbolicLinkKey) }
    
    /// True for the root directory of a volume.
    public var isVolume: Bool? { return _get(.isVolumeKey) }
    
    /// True for packaged directories. 
    ///
    /// - note: You can only set or clear this property on directories; if you try to set this property on non-directory objects, the property is ignored. If the directory is a package for some other reason (extension type, etc), setting this property to false will have no effect.
    public var isPackage: Bool? {
        get { return _get(.isPackageKey) }
        set { _set(.isPackageKey, newValue: newValue) }
    }
    
    
#if os(macOS)
#endif
    
    /// True for system-immutable resources.
    public var isSystemImmutable: Bool? { return _get(.isSystemImmutableKey) }
    
    /// True for user-immutable resources
    public var isUserImmutable: Bool? {
        get { return _get(.isUserImmutableKey) }
        set { _set(.isUserImmutableKey, newValue: newValue) }
    }
    
    /// True for resources normally not displayed to users.
    /// 
    /// - note: If the resource is a hidden because its name starts with a period, setting this property to false will not change the property.
    public var isHidden: Bool? {
        get { return _get(.isHiddenKey) }
        set { _set(.isHiddenKey, newValue: newValue) }
    }
    
    /// True for resources whose filename extension is removed from the localized name property.
    public var hasHiddenExtension: Bool? {
        get { return _get(.hasHiddenExtensionKey) }
        set { _set(.hasHiddenExtensionKey, newValue: newValue) }
    }
    
    /// The date the resource was created.
    public var creationDate: Date? {
        get { return _get(.creationDateKey) }
        set { _set(.creationDateKey, newValue: newValue) }
    }
    
    /// The date the resource was last accessed.
    public var contentAccessDate: Date? {
        get { return _get(.contentAccessDateKey) }
        set { _set(.contentAccessDateKey, newValue: newValue) }
    }
    
    /// The time the resource content was last modified.
    public var contentModificationDate: Date? {
        get { return _get(.contentModificationDateKey) }
        set { _set(.contentModificationDateKey, newValue: newValue) }
    }
    
    /// The time the resource's attributes were last modified.
    public var attributeModificationDate: Date? { return _get(.attributeModificationDateKey) }
    
    /// Number of hard links to the resource.
    public var linkCount: Int? { return _get(.linkCountKey) }
    
    /// The resource's parent directory, if any.
    public var parentDirectory: URL? { return _get(.parentDirectoryURLKey) }
    
    /// URL of the volume on which the resource is stored.
    public var volume: URL? { return _get(.volumeURLKey) }
    
    /// Uniform type identifier (UTI) for the resource.
    public var typeIdentifier: String? { return _get(.typeIdentifierKey) }
    
    /// User-visible type or "kind" description.
    public var localizedTypeDescription: String? { return _get(.localizedTypeDescriptionKey) }
    
    /// The label number assigned to the resource.
    public var labelNumber: Int? {
        get { return _get(.labelNumberKey) }
        set { _set(.labelNumberKey, newValue: newValue) }
    }
    
    
    /// The user-visible label text.
    public var localizedLabel: String? {
        get { return _get(.localizedLabelKey) }
    }
        
    /// An identifier which can be used to compare two file system objects for equality using `isEqual`.
    ///
    /// Two object identifiers are equal if they have the same file system path or if the paths are linked to same inode on the same file system. This identifier is not persistent across system restarts.
    public var fileResourceIdentifier: (NSCopying & NSCoding & NSSecureCoding & NSObjectProtocol)? { return _get(.fileResourceIdentifierKey) }
    
    /// An identifier that can be used to identify the volume the file system object is on. 
    ///
    /// Other objects on the same volume will have the same volume identifier and can be compared using for equality using `isEqual`. This identifier is not persistent across system restarts.
    public var volumeIdentifier: (NSCopying & NSCoding & NSSecureCoding & NSObjectProtocol)? { return _get(.volumeIdentifierKey) }
    
    /// The optimal block size when reading or writing this file's data, or nil if not available.
    public var preferredIOBlockSize: Int? { return _get(.preferredIOBlockSizeKey) }
    
    /// True if this process (as determined by EUID) can read the resource.
    public var isReadable: Bool? { return _get(.isReadableKey) }
    
    /// True if this process (as determined by EUID) can write to the resource.
    public var isWritable: Bool? { return _get(.isWritableKey) }
    
    /// True if this process (as determined by EUID) can execute a file resource or search a directory resource.
    public var isExecutable: Bool? { return _get(.isExecutableKey) }
    
    /// The file system object's security information encapsulated in a FileSecurity object.
    public var fileSecurity: NSFileSecurity? {
        get { return _get(.fileSecurityKey) }
        set { _set(.fileSecurityKey, newValue: newValue) }
    }
    
    /// True if resource should be excluded from backups, false otherwise.
    ///
    /// This property is only useful for excluding cache and other application support files which are not needed in a backup. Some operations commonly made to user documents will cause this property to be reset to false and so this property should not be used on user documents.
    public var isExcludedFromBackup: Bool? {
        get { return _get(.isExcludedFromBackupKey) }
        set { _set(.isExcludedFromBackupKey, newValue: newValue) }
    }
    
#if os(macOS)
#endif
    /// The URL's path as a file system path.
    public var path: String? { return _get(.pathKey) }
    
    
    /// True if this URL is a file system trigger directory. Traversing or opening a file system trigger will cause an attempt to mount a file system on the trigger directory.
    public var isMountTrigger: Bool? { return _get(.isMountTriggerKey) }
    
    
    
    
#if os(macOS)
#endif
    
    
    /// The user-visible volume format.
    public var volumeLocalizedFormatDescription : String? { return _get(.volumeLocalizedFormatDescriptionKey) }
    
    /// Total volume capacity in bytes.
    public var volumeTotalCapacity : Int? { return _get(.volumeTotalCapacityKey) }
    
    /// Total free space in bytes.
    public var volumeAvailableCapacity : Int? { return _get(.volumeAvailableCapacityKey) }
    
#if os(macOS) || os(iOS)
    
#endif
    
    /// Total number of resources on the volume.
    public var volumeResourceCount : Int? { return _get(.volumeResourceCountKey) }
    
    /// true if the volume format supports persistent object identifiers and can look up file system objects by their IDs.
    public var volumeSupportsPersistentIDs : Bool? { return _get(.volumeSupportsPersistentIDsKey) }
    
    /// true if the volume format supports symbolic links.
    public var volumeSupportsSymbolicLinks : Bool? { return _get(.volumeSupportsSymbolicLinksKey) }
    
    /// true if the volume format supports hard links.
    public var volumeSupportsHardLinks : Bool? { return _get(.volumeSupportsHardLinksKey) }
    
    /// true if the volume format supports a journal used to speed recovery in case of unplanned restart (such as a power outage or crash). This does not necessarily mean the volume is actively using a journal. 
    public var volumeSupportsJournaling : Bool? { return _get(.volumeSupportsJournalingKey) }
    
    /// true if the volume is currently using a journal for speedy recovery after an unplanned restart. 
    public var volumeIsJournaling : Bool? { return _get(.volumeIsJournalingKey) }
    
    /// true if the volume format supports sparse files, that is, files which can have 'holes' that have never been written to, and thus do not consume space on disk. A sparse file may have an allocated size on disk that is less than its logical length.
    public var volumeSupportsSparseFiles : Bool? { return _get(.volumeSupportsSparseFilesKey) }
    
    /// For security reasons, parts of a file (runs) that have never been written to must appear to contain zeroes. true if the volume keeps track of allocated but unwritten runs of a file so that it can substitute zeroes without actually writing zeroes to the media. 
    public var volumeSupportsZeroRuns : Bool? { return _get(.volumeSupportsZeroRunsKey) }

    /// true if the volume format treats upper and lower case characters in file and directory names as different. Otherwise an upper case character is equivalent to a lower case character, and you can't have two names that differ solely in the case of the characters. 
    public var volumeSupportsCaseSensitiveNames : Bool? { return _get(.volumeSupportsCaseSensitiveNamesKey) }

    /// true if the volume format preserves the case of file and directory names.  Otherwise the volume may change the case of some characters (typically making them all upper or all lower case). 
    public var volumeSupportsCasePreservedNames : Bool? { return _get(.volumeSupportsCasePreservedNamesKey) }

    /// true if the volume supports reliable storage of times for the root directory. 
    public var volumeSupportsRootDirectoryDates : Bool? { return _get(.volumeSupportsRootDirectoryDatesKey) }

    /// true if the volume supports returning volume size values (`volumeTotalCapacity` and `volumeAvailableCapacity`).
    public var volumeSupportsVolumeSizes : Bool? { return _get(.volumeSupportsVolumeSizesKey) }

    /// true if the volume can be renamed. 
    public var volumeSupportsRenaming : Bool? { return _get(.volumeSupportsRenamingKey) }

    /// true if the volume implements whole-file flock(2) style advisory locks, and the O_EXLOCK and O_SHLOCK flags of the open(2) call. 
    public var volumeSupportsAdvisoryFileLocking : Bool? { return _get(.volumeSupportsAdvisoryFileLockingKey) }

    /// true if the volume implements extended security (ACLs). 
    public var volumeSupportsExtendedSecurity : Bool? { return _get(.volumeSupportsExtendedSecurityKey) }

    /// true if the volume should be visible via the GUI (i.e., appear on the Desktop as a separate volume). 
    public var volumeIsBrowsable : Bool? { return _get(.volumeIsBrowsableKey) }

    /// The largest file size (in bytes) supported by this file system, or nil if this cannot be determined. 
    public var volumeMaximumFileSize : Int? { return _get(.volumeMaximumFileSizeKey) }

    /// true if the volume's media is ejectable from the drive mechanism under software control. 
    public var volumeIsEjectable : Bool? { return _get(.volumeIsEjectableKey) }

    /// true if the volume's media is removable from the drive mechanism. 
    public var volumeIsRemovable : Bool? { return _get(.volumeIsRemovableKey) }

    /// true if the volume's device is connected to an internal bus, false if connected to an external bus, or nil if not available. 
    public var volumeIsInternal : Bool? { return _get(.volumeIsInternalKey) }

    /// true if the volume is automounted. Note: do not mistake this with the functionality provided by kCFURLVolumeSupportsBrowsingKey. 
    public var volumeIsAutomounted : Bool? { return _get(.volumeIsAutomountedKey) }

    /// true if the volume is stored on a local device. 
    public var volumeIsLocal : Bool? { return _get(.volumeIsLocalKey) }

    /// true if the volume is read-only. 
    public var volumeIsReadOnly : Bool? { return _get(.volumeIsReadOnlyKey) }

    /// The volume's creation date, or nil if this cannot be determined. 
    public var volumeCreationDate : Date? { return _get(.volumeCreationDateKey) }

    /// The `URL` needed to remount a network volume, or nil if not available.
    public var volumeURLForRemounting : URL? { return _get(.volumeURLForRemountingKey) }

    /// The volume's persistent `UUID` as a string, or nil if a persistent `UUID` is not available for the volume.
    public var volumeUUIDString : String? { return _get(.volumeUUIDStringKey) }

    /// The name of the volume 
    public var volumeName : String? {
        get { return _get(.volumeNameKey) }
        set { _set(.volumeNameKey, newValue: newValue) }
    }
    
    /// The user-presentable name of the volume 
    public var volumeLocalizedName : String? { return _get(.volumeLocalizedNameKey) }
    


    /// true if the volume supports transparent decompression of compressed files using decmpfs. 
    @available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
    public var volumeSupportsCompression : Bool? { return _get(.volumeSupportsCompressionKey) }
    
    /// true if the volume supports clonefile(2).
    @available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
    public var volumeSupportsFileCloning : Bool? { return _get(.volumeSupportsFileCloningKey) }
    
    /// true if the volume supports renamex_np(2)'s RENAME_SWAP option.
    @available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
    public var volumeSupportsSwapRenaming : Bool? { return _get(.volumeSupportsSwapRenamingKey) }
    
    /// true if the volume supports renamex_np(2)'s RENAME_EXCL option.
    @available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
    public var volumeSupportsExclusiveRenaming : Bool? { return _get(.volumeSupportsExclusiveRenamingKey) }
    
    /// true if the volume supports making files immutable with isUserImmutable or isSystemImmutable.
    @available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
    public var volumeSupportsImmutableFiles : Bool? { return _get(.volumeSupportsImmutableFilesKey) }
    
    /// true if the volume supports setting POSIX access permissions with fileSecurity.
    @available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
    public var volumeSupportsAccessPermissions : Bool? { return _get(.volumeSupportsAccessPermissionsKey) }
    
    /// true if this item is synced to the cloud, false if it is only a local file. 
    public var isUbiquitousItem : Bool? { return _get(.isUbiquitousItemKey) }

    /// true if this item has conflicts outstanding. 
    public var ubiquitousItemHasUnresolvedConflicts : Bool? { return _get(.ubiquitousItemHasUnresolvedConflictsKey) }

    /// true if data is being downloaded for this item. 
    public var ubiquitousItemIsDownloading : Bool? { return _get(.ubiquitousItemIsDownloadingKey) }

    /// true if there is data present in the cloud for this item. 
    public var ubiquitousItemIsUploaded : Bool? { return _get(.ubiquitousItemIsUploadedKey) }

    /// true if data is being uploaded for this item. 
    public var ubiquitousItemIsUploading : Bool? { return _get(.ubiquitousItemIsUploadingKey) }
    
    

    
    
    
#if os(macOS) || os(iOS)
    // true if ubiquitous item is shared.
    
    // The current user's role for this shared item, or nil if not shared
    
    // The permissions for the current user, or nil if not shared.
    
    // The name components for the owner, or nil if not shared.
    
    // The name components for the most recent editor, or nil if not shared.
#endif
    
#if !os(macOS)
    /// The protection level for this file
    @available(iOS 9.0, *)
    public var fileProtection : URLFileProtection? { return _get(.fileProtectionKey) }
#endif
    
    /// Total file size in bytes
    ///
    /// - note: Only applicable to regular files.
    public var fileSize : Int? { return _get(.fileSizeKey) }
    
    /// Total size allocated on disk for the file in bytes (number of blocks times block size)
    ///
    /// - note: Only applicable to regular files.
    public var fileAllocatedSize : Int? { return _get(.fileAllocatedSizeKey) }
    
    /// Total displayable size of the file in bytes (this may include space used by metadata), or nil if not available.
    ///
    /// - note: Only applicable to regular files.
    public var totalFileSize : Int? { return _get(.totalFileSizeKey) }
    
    /// Total allocated size of the file in bytes (this may include space used by metadata), or nil if not available. This can be less than the value returned by `totalFileSize` if the resource is compressed.
    ///
    /// - note: Only applicable to regular files.
    public var totalFileAllocatedSize : Int? { return _get(.totalFileAllocatedSizeKey) }

    /// true if the resource is a Finder alias file or a symlink, false otherwise
    ///
    /// - note: Only applicable to regular files.
    public var isAliasFile : Bool? { return _get(.isAliasFileKey) }

}
