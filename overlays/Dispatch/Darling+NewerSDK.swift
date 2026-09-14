//===----------------------------------------------------------------------===//
//
// Additions for binaries built against newer macOS SDKs than the last open-source
// Dispatch overlay (Swift 5.4). Written for Darling from the public API surface.
//
//===----------------------------------------------------------------------===//

@_implementationOnly import _SwiftDispatchOverlayShims

private func clampedIntProduct(_ m1: Int, _ m2: UInt64) -> Int {
	assert(m2 > 0, "multiplier must be positive")
	let (result, overflow) = m1.multipliedReportingOverflow(by: Int(m2))
	if overflow {
		return m1 > 0 ? Int.max : Int.min
	}
	return result
}

// DispatchTime's distance/advanced moved out of the Combine scheduler support into the base overlay.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension DispatchTime {
	public func distance(to other: DispatchTime) -> DispatchTimeInterval {
		let lhs = other.uptimeNanoseconds
		let rhs = uptimeNanoseconds
		if lhs >= rhs {
			return DispatchTimeInterval.nanoseconds(Int(lhs - rhs))
		} else {
			return DispatchTimeInterval.nanoseconds(0 - Int(rhs - lhs))
		}
	}

	public func advanced(by n: DispatchTimeInterval) -> DispatchTime {
		return self + n
	}
}

// DispatchSerialQueue (macOS 14 SDK).
@available(macOS 10.10, iOS 8.0, *)
extension OS_dispatch_queue_serial {
	public struct Attributes : OptionSet {
		public let rawValue: UInt64
		public init(rawValue: UInt64) { self.rawValue = rawValue }

		@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
		public static let initiallyInactive = Attributes(rawValue: 1<<2)

		fileprivate func _attr() -> __OS_dispatch_queue_attr? {
			var attr: __OS_dispatch_queue_attr? = nil
			if #available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *) {
				if self.contains(.initiallyInactive) {
					attr = __dispatch_queue_attr_make_initially_inactive(attr)
				}
			}
			return attr
		}
	}

	public convenience init(
		label: String,
		qos: DispatchQoS = .unspecified,
		attributes: Attributes = [],
		autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit,
		target: DispatchQueue? = nil)
	{
		var attr = attributes._attr()
		if autoreleaseFrequency != .inherit {
			attr = autoreleaseFrequency._attr(attr: attr)
		}
		if qos != .unspecified {
			attr = __dispatch_queue_attr_make_with_qos_class(attr, qos.qosClass.rawValue, Int32(qos.relativePriority))
		}
		self.init(__label: label, attr: attr, queue: target)
	}
}
