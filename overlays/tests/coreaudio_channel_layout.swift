// Copyright (C) 2026 Lubos Dolezel
//
// The CoreAudio Swift overlay: the AudioBufferList helpers, the AudioChannelLayout views and
// ManagedAudioChannelLayout. Written against the public CoreAudio Swift API; builds against the
// macOS SDK as well as Darling's.
import CoreAudio
import Foundation

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { fatalError(message) }
}

// AudioBufferList helpers
let list = AudioBufferList.allocate(maximumBuffers: 2)
check(list.count == 2, "allocate sets the buffer count")
check(AudioBufferList.sizeInBytes(maximumBuffers: 2) == MemoryLayout<AudioBufferList>.size + MemoryLayout<AudioBuffer>.stride,
      "sizeInBytes covers the second buffer")
var samples: [Float] = [1, 2, 3, 4]
samples.withUnsafeMutableBufferPointer { p in
    list[0] = AudioBuffer(p, numberOfChannels: 2)
    check(list[0].mDataByteSize == 16 && list[0].mNumberChannels == 2, "AudioBuffer(_:numberOfChannels:)")
    let back = UnsafeBufferPointer<Float>(list[0])
    check(back.count == 4 && back[3] == 4, "UnsafeBufferPointer(AudioBuffer)")
    UnsafeMutableBufferPointer<Float>(list[0])[0] = 9
}
check(samples[0] == 9, "UnsafeMutableBufferPointer(AudioBuffer) writes through")
list[1].mNumberChannels = 7
check(list.map { $0.mNumberChannels } == [2, 7], "subscript modify and iteration")
free(list.unsafeMutablePointer)

// AudioChannelLayout size, allocation and views
let descriptionSize = MemoryLayout<AudioChannelDescription>.stride
check(AudioChannelLayout.sizeInBytes(maximumDescriptions: 1) == MemoryLayout<AudioChannelLayout>.size,
      "sizeInBytes(1) is the struct size")
check(AudioChannelLayout.sizeInBytes(maximumDescriptions: 3) == MemoryLayout<AudioChannelLayout>.size + 2 * descriptionSize,
      "sizeInBytes(3) adds two more descriptions")
let layout = AudioChannelLayout.allocate(maximumDescriptions: 3)
check(layout.count == 3, "allocate sets the description count")
layout[1].mChannelLabel = kAudioChannelLabel_Right
layout[2].mCoordinates.1 = 0.5
let readOnly = AudioChannelLayout.UnsafePointer(layout.unsafePointer)
check(readOnly.count == 3 && readOnly[1].mChannelLabel == kAudioChannelLabel_Right && readOnly[2].mCoordinates.1 == 0.5,
      "UnsafePointer view reads")
check(AudioChannelLayout.UnsafePointer(nil) == nil && AudioChannelLayout.UnsafeMutablePointer(nil) == nil,
      "failable initialisers return nil for nil")
check(readOnly[0] == readOnly[0] && !(readOnly[0] == readOnly[1]), "AudioChannelDescription ==")

// ManagedAudioChannelLayout
let stereo = ManagedAudioChannelLayout(tag: kAudioChannelLayoutTag_Stereo)
check(stereo.tag == kAudioChannelLayoutTag_Stereo && stereo.numberOfChannels == 2, "init(tag:)")
check(stereo.channelDescriptions.count == 1 && stereo.sizeInBytes == MemoryLayout<AudioChannelLayout>.size,
      "init(tag:) holds one description (quirk)")
var bits = ManagedAudioChannelLayout(tag: kAudioChannelLayoutTag_UseChannelBitmap)
bits.bitmap = [.bit_Left, .bit_Right, .bit_Center]
check(bits.numberOfChannels == 3, "bitmap layout channel count")
let left = AudioChannelDescription(mChannelLabel: kAudioChannelLabel_Left, mChannelFlags: [], mCoordinates: (0, 0, 0))
let right = AudioChannelDescription(mChannelLabel: kAudioChannelLabel_Right, mChannelFlags: [], mCoordinates: (0, 0, 0))
var a = ManagedAudioChannelLayout(channelDescriptions: [left, right])
check(a.numberOfChannels == 2 && a.channelDescriptions.count == 2
      && a.channelDescriptions[1].mChannelLabel == kAudioChannelLabel_Right, "init(channelDescriptions:)")
check(a.sizeInBytes == AudioChannelLayout.sizeInBytes(maximumDescriptions: 2), "sizeInBytes")
var b = a
b.channelDescriptions[0].mChannelLabel = kAudioChannelLabel_Center
check(a.channelDescriptions[0].mChannelLabel == kAudioChannelLabel_Left
      && b.channelDescriptions[0].mChannelLabel == kAudioChannelLabel_Center, "copies are independent")
check(a != b && a == ManagedAudioChannelLayout(channelDescriptions: [left, right]), "Equatable")
b.setAllToUnknown()
check(b.channelDescriptions.allSatisfy { $0.mChannelLabel == kAudioChannelLabel_Unknown }, "setAllToUnknown")
check(a.withUnsafePointer { $0.pointee.mNumberChannelDescriptions } == 2, "withUnsafePointer")
a.withUnsafeMutablePointer { $0.pointee.mChannelBitmap = .bit_LFEScreen }
check(a.bitmap == .bit_LFEScreen, "withUnsafeMutablePointer")
check(ManagedAudioChannelLayout(maximumDescriptions: 4).channelDescriptions.count == 4, "init(maximumDescriptions:)")

var freed = false
do {
    let adopted = ManagedAudioChannelLayout(audioChannelLayoutPointer: readOnly) { p in
        free(UnsafeMutableRawPointer(mutating: p.unsafePointer))
        freed = true
    }
    var changed = adopted
    changed.tag = kAudioChannelLayoutTag_Mono
    check(adopted.channelDescriptions[1].mChannelLabel == kAudioChannelLabel_Right
          && adopted.tag == kAudioChannelLayoutTag_UseChannelDescriptions
          && changed.tag == kAudioChannelLayoutTag_Mono, "an adopted layout is copied on change")
}
check(freed, "the deallocator runs for an adopted layout")
print("coreaudio_channel_layout: all passed")
