// Darling's CoreGraphics (Cocotron) has no Clang module of its own: its C types and CGFloat come through
// CoreFoundation and Foundation. This module exists so the Clang importer can map C `CGFloat` to
// `CoreGraphics.CGFloat` (defined in the CoreFoundation overlay), and so arm64 binaries that autolink
// libswiftCoreGraphics find a slice.
@_exported import CoreFoundation
