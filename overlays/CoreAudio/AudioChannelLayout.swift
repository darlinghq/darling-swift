import Darwin
@_exported import CoreAudio // Clang module

// AudioChannelLayout, like AudioBufferList, ends in a variable-length array: mNumberChannelDescriptions
// descriptions, of which the struct declares one.

private func descriptions(of layout: UnsafeMutableRawPointer) -> UnsafeMutablePointer<AudioChannelDescription> {
	let offset = MemoryLayout<AudioChannelLayout>.offset(of: \AudioChannelLayout.mChannelDescriptions)!
	return (layout + offset).assumingMemoryBound(to: AudioChannelDescription.self)
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AudioChannelLayout {
	/// The size of an AudioChannelLayout that holds `maximumDescriptions` channel descriptions.
	///
	/// QUIRK: a `maximumDescriptions` below 1 stops the program with a precondition failure instead of
	/// yielding the size of the bare struct. Not documented. Evidence: black-box observation on macOS 26.7.3
	/// (tier 2): `sizeInBytes(maximumDescriptions: 0)` traps while 1 gives 32 and 3 gives 72 bytes, as for
	/// AudioBufferList.sizeInBytes(maximumBuffers:). Test: overlays/tests/coreaudio_channel_layout.swift
	/// (the sizes; the trap itself is not testable in-process).
	public static func sizeInBytes(maximumDescriptions: Int) -> Int {
		precondition(maximumDescriptions >= 1, "AudioChannelLayout should contain at least one AudioChannelDescription")
		let offset = MemoryLayout<AudioChannelLayout>.offset(of: \AudioChannelLayout.mChannelDescriptions)!
		return offset + maximumDescriptions * MemoryLayout<AudioChannelDescription>.stride
	}

	/// A zeroed AudioChannelLayout with room for `maximumDescriptions` descriptions; free it with `free`.
	public static func allocate(maximumDescriptions: Int) -> AudioChannelLayout.UnsafeMutablePointer {
		let raw = calloc(sizeInBytes(maximumDescriptions: maximumDescriptions), 1)!
		let layout = UnsafeMutablePointer(raw.assumingMemoryBound(to: AudioChannelLayout.self))
		layout.count = maximumDescriptions
		return layout
	}

	/// A collection view of an AudioChannelLayout's channel descriptions.
	public struct UnsafeMutablePointer {
		public var unsafeMutablePointer: Swift.UnsafeMutablePointer<AudioChannelLayout>

		public init(_ p: Swift.UnsafeMutablePointer<AudioChannelLayout>) {
			unsafeMutablePointer = p
		}

		public init?(_ p: Swift.UnsafeMutablePointer<AudioChannelLayout>?) {
			guard let p = p else { return nil }
			self.init(p)
		}

		public var unsafePointer: Swift.UnsafePointer<AudioChannelLayout> { Swift.UnsafePointer(unsafeMutablePointer) }

		/// The number of descriptions, mNumberChannelDescriptions.
		public var count: Int {
			get { Int(unsafeMutablePointer.pointee.mNumberChannelDescriptions) }
			nonmutating set { unsafeMutablePointer.pointee.mNumberChannelDescriptions = UInt32(newValue) }
		}
	}

	/// A read-only collection view of an AudioChannelLayout's channel descriptions.
	public struct UnsafePointer {
		public var unsafePointer: Swift.UnsafePointer<AudioChannelLayout>

		public init(_ p: Swift.UnsafePointer<AudioChannelLayout>) {
			unsafePointer = p
		}

		public init?(_ p: Swift.UnsafePointer<AudioChannelLayout>?) {
			guard let p = p else { return nil }
			self.init(p)
		}

		public var count: Int { Int(unsafePointer.pointee.mNumberChannelDescriptions) }
	}
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AudioChannelLayout.UnsafeMutablePointer: MutableCollection, RandomAccessCollection {
	public typealias Element = AudioChannelDescription
	public typealias Index = Int

	public var startIndex: Int { 0 }
	public var endIndex: Int { count }

	public subscript(index: Int) -> AudioChannelDescription {
		_read {
			precondition(index >= 0 && index < count, "subscript index out of range")
			yield descriptions(of: UnsafeMutableRawPointer(unsafeMutablePointer))[index]
		}
		nonmutating _modify {
			precondition(index >= 0 && index < count, "subscript index out of range")
			yield &descriptions(of: UnsafeMutableRawPointer(unsafeMutablePointer))[index]
		}
	}
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AudioChannelLayout.UnsafePointer: RandomAccessCollection {
	public typealias Element = AudioChannelDescription
	public typealias Index = Int

	public var startIndex: Int { 0 }
	public var endIndex: Int { count }

	public subscript(index: Int) -> AudioChannelDescription {
		_read {
			precondition(index >= 0 && index < count, "subscript index out of range")
			yield descriptions(of: UnsafeMutableRawPointer(mutating: unsafePointer))[index]
		}
	}
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension AudioChannelDescription {
	public static func == (lhs: AudioChannelDescription, rhs: AudioChannelDescription) -> Bool {
		lhs.mChannelLabel == rhs.mChannelLabel && lhs.mChannelFlags == rhs.mChannelFlags
			&& lhs.mCoordinates.0 == rhs.mCoordinates.0 && lhs.mCoordinates.1 == rhs.mCoordinates.1
			&& lhs.mCoordinates.2 == rhs.mCoordinates.2
	}
}

/// An AudioChannelLayout with value semantics: copies share one allocation until one of them changes.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public struct ManagedAudioChannelLayout {
	fileprivate final class Storage {
		let layout: Swift.UnsafeMutablePointer<AudioChannelLayout>
		/// Frees `layout`: the caller's deallocator for an adopted layout, free for one made here.
		let deallocator: (Swift.UnsafeMutablePointer<AudioChannelLayout>) -> Void
		/// An adopted layout is read-only: the first change copies it.
		let isAdopted: Bool

		init(_ layout: Swift.UnsafeMutablePointer<AudioChannelLayout>, isAdopted: Bool,
		     deallocator: @escaping (Swift.UnsafeMutablePointer<AudioChannelLayout>) -> Void) {
			self.layout = layout
			self.isAdopted = isAdopted
			self.deallocator = deallocator
		}

		convenience init(maximumDescriptions: Int) {
			let layout = AudioChannelLayout.allocate(maximumDescriptions: maximumDescriptions).unsafeMutablePointer
			self.init(layout, isAdopted: false) { free($0) }
		}

		var count: Int { Int(layout.pointee.mNumberChannelDescriptions) }
		var descriptions: Swift.UnsafeMutablePointer<AudioChannelDescription> {
			CoreAudio.descriptions(of: UnsafeMutableRawPointer(layout))
		}

		func copy() -> Storage {
			// A layout adopted from elsewhere may declare no descriptions; it still holds the one the struct has.
			let storage = Storage(maximumDescriptions: max(count, 1))
			memcpy(storage.layout, layout, AudioChannelLayout.sizeInBytes(maximumDescriptions: max(count, 1)))
			return storage
		}

		deinit { deallocator(layout) }
	}

	fileprivate var storage: Storage

	public init(audioChannelLayoutPointer: AudioChannelLayout.UnsafePointer,
	            deallocator: @escaping (AudioChannelLayout.UnsafePointer) -> Void) {
		storage = Storage(Swift.UnsafeMutablePointer(mutating: audioChannelLayoutPointer.unsafePointer), isAdopted: true) {
			deallocator(AudioChannelLayout.UnsafePointer(Swift.UnsafePointer($0)))
		}
	}

	public init(tag: AudioChannelLayoutTag) {
		// QUIRK: the layout made from a tag holds one (zeroed) channel description. Not documented.
		// Evidence: black-box observation on macOS 26.7.3 (tier 2): channelDescriptions.count is 1 and
		// sizeInBytes is 32 for init(tag: kAudioChannelLayoutTag_Stereo).
		// Test: overlays/tests/coreaudio_channel_layout.swift ("init(tag:) holds one description").
		storage = Storage(maximumDescriptions: 1)
		storage.layout.pointee.mChannelLayoutTag = tag
	}

	public init(maximumDescriptions: Int) {
		storage = Storage(maximumDescriptions: maximumDescriptions)
	}

	public init(channelDescriptions: [AudioChannelDescription]) {
		storage = Storage(maximumDescriptions: channelDescriptions.count)
		storage.descriptions.update(from: channelDescriptions, count: channelDescriptions.count)
	}

	private mutating func makeUnique() {
		if storage.isAdopted || !isKnownUniquelyReferenced(&storage) {
			storage = storage.copy()
		}
	}

	public var tag: AudioChannelLayoutTag {
		get { storage.layout.pointee.mChannelLayoutTag }
		set {
			makeUnique()
			storage.layout.pointee.mChannelLayoutTag = newValue
		}
	}

	public var bitmap: AudioChannelBitmap {
		get { storage.layout.pointee.mChannelBitmap }
		set {
			makeUnique()
			storage.layout.pointee.mChannelBitmap = newValue
		}
	}

	/// Describes the layout by its channel descriptions, every channel's label unknown.
	public mutating func setAllToUnknown() {
		makeUnique()
		storage.layout.pointee.mChannelLayoutTag = kAudioChannelLayoutTag_UseChannelDescriptions
		storage.layout.pointee.mChannelBitmap = []
		for i in 0..<storage.count {
			storage.descriptions[i] = AudioChannelDescription(mChannelLabel: kAudioChannelLabel_Unknown,
			                                                  mChannelFlags: [], mCoordinates: (0, 0, 0))
		}
	}

	public var channelDescriptions: ChannelDescriptions {
		_read { yield ChannelDescriptions(storage: storage) }
		_modify {
			makeUnique()
			// Lend the storage out, so that the descriptions hold its only reference while they change.
			var descriptions = ChannelDescriptions(storage: storage)
			storage = ManagedAudioChannelLayout.lent
			defer { storage = descriptions.storage }
			yield &descriptions
		}
	}

	private static let lent = Storage(maximumDescriptions: 1)

	public var sizeInBytes: Int { AudioChannelLayout.sizeInBytes(maximumDescriptions: max(storage.count, 1)) }

	/// The channels the tag stands for: its descriptions, the bitmap's channels, or the count
	/// in the tag's low 16 bits.
	public var numberOfChannels: Int {
		switch tag {
		case kAudioChannelLayoutTag_UseChannelDescriptions: return storage.count
		case kAudioChannelLayoutTag_UseChannelBitmap: return bitmap.rawValue.nonzeroBitCount
		default: return Int(tag & 0xFFFF)
		}
	}

	public func withUnsafePointer<Result>(_ body: (Swift.UnsafePointer<AudioChannelLayout>) throws -> Result) rethrows -> Result {
		try withExtendedLifetime(storage) { try body(Swift.UnsafePointer(storage.layout)) }
	}

	public mutating func withUnsafeMutablePointer<Result>(_ body: (Swift.UnsafeMutablePointer<AudioChannelLayout>) throws -> Result) rethrows -> Result {
		makeUnique()
		return try withExtendedLifetime(storage) { try body(storage.layout) }
	}

	public struct ChannelDescriptions: MutableCollection, RandomAccessCollection {
		public typealias Element = AudioChannelDescription
		public typealias Index = Int

		fileprivate var storage: Storage

		public var startIndex: Int { 0 }
		public var endIndex: Int { storage.count }
		public var count: Int { storage.count }

		public subscript(index: Int) -> AudioChannelDescription {
			_read {
				precondition(index >= 0 && index < count, "subscript index out of range")
				yield storage.descriptions[index]
			}
			_modify {
				precondition(index >= 0 && index < count, "subscript index out of range")
				if storage.isAdopted || !isKnownUniquelyReferenced(&storage) {
					storage = storage.copy()
				}
				yield &storage.descriptions[index]
			}
		}
	}
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ManagedAudioChannelLayout.ChannelDescriptions: Equatable {
	public static func == (lhs: ManagedAudioChannelLayout.ChannelDescriptions,
	                       rhs: ManagedAudioChannelLayout.ChannelDescriptions) -> Bool {
		lhs.elementsEqual(rhs, by: ==)
	}
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension ManagedAudioChannelLayout: Equatable {
	public static func == (lhs: ManagedAudioChannelLayout, rhs: ManagedAudioChannelLayout) -> Bool {
		lhs.tag == rhs.tag && lhs.bitmap == rhs.bitmap && lhs.channelDescriptions == rhs.channelDescriptions
	}
}
