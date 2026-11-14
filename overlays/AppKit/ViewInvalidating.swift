// NSView.Invalidating (macOS 12), the property wrapper that invalidates a view when a property changes, the
// NSViewInvalidating protocol and the Invalidations types that conform to it.
//
// Provenance. Names: Reminders and App Store import Invalidating (nominal type, init(wrappedValue:_:), the
// static subscript's get, set and modify), Invalidations.Layout and .IntrinsicContentSize, Invalidations.Tuple and its
// conformance, the two-invalidation init(wrappedValue:_:_:), and NSViewInvalidating with invalidate(view:)
// (rung 5, llvm-nm -u -m). Declarations: Apple's public documentation,
// https://developer.apple.com/documentation/appkit/nsview/invalidating (`<Value: Equatable, InvalidationType:
// NSViewInvalidating>`, initializers for one to ten invalidations, where several are nested Tuples:
// `Tuple<Tuple<I1, I2>, I3>` for three, `Tuple<Tuple<I1, I2>, Tuple<I3, I4>>` for four),
// .../nsview/invalidations (Constraints, Display, IntrinsicContentSize, Layout, RestorableState, Tuple<Invalidation1,
// Invalidation2>) and .../nsviewinvalidating (`invalidate(view:)`). Each invalidation sets the flag or calls the method
// its name says (needsLayout, needsDisplay, needsUpdateConstraints, invalidateIntrinsicContentSize,
// invalidateRestorableState); the documentation says the wrapper sets the flag "causing the system to redraw".
// Layout that cannot matter: every type here is a non-frozen struct or an enum namespace, under library evolution.
// GUESS (no public source): that the wrapper invalidates only when the new value differs from the old (the Equatable
// constraint implies a comparison; the documentation does not say), the requirement set of NSViewInvalidating (one
// method), and that Tuple invalidates the first and then the second. NEEDS-REAL-MAC: whether the Invalidations structs
// are frozen upstream (an app imports a protocol witness table for Layout directly, which hints at it; both are empty
// structs, so their size is zero either way) and whether the non-resilience arguments above hold for them.
// The static members `layout`, `display`, `constraints`, `intrinsicContentSize` and `restorableState` are the documented
// pages' `static var x: NSView.Invalidations.X { get }`, written as constrained protocol-extension members.
// Initializers for five to ten invalidations are left out because no named app imports them.

@_exported import Foundation
#if DARLING_APPKIT_CLANG_MODULE
@_exported import AppKit
#else
import _DarlingAppKitShims
#endif

/// A way of telling a view that something it displays has changed.
public protocol NSViewInvalidating {
    /// Marks `view` as needing the update this invalidation stands for.
    func invalidate(view: NSView)
}

extension NSViewInvalidating where Self == NSView.Invalidations.Layout {
    public static var layout: NSView.Invalidations.Layout { return NSView.Invalidations.Layout() }
}

extension NSViewInvalidating where Self == NSView.Invalidations.Display {
    public static var display: NSView.Invalidations.Display { return NSView.Invalidations.Display() }
}

extension NSViewInvalidating where Self == NSView.Invalidations.Constraints {
    public static var constraints: NSView.Invalidations.Constraints { return NSView.Invalidations.Constraints() }
}

extension NSViewInvalidating where Self == NSView.Invalidations.IntrinsicContentSize {
    public static var intrinsicContentSize: NSView.Invalidations.IntrinsicContentSize { return NSView.Invalidations.IntrinsicContentSize() }
}

extension NSViewInvalidating where Self == NSView.Invalidations.RestorableState {
    public static var restorableState: NSView.Invalidations.RestorableState { return NSView.Invalidations.RestorableState() }
}

extension NSView {
    /// The invalidations a property can request.
    public enum Invalidations {
        /// Asks for a new layout pass.
        public struct Layout: NSViewInvalidating {
            public init() {}
            public func invalidate(view: NSView) { view.needsLayout = true }
        }

        /// Asks for a redraw.
        public struct Display: NSViewInvalidating {
            public init() {}
            public func invalidate(view: NSView) { view.needsDisplay = true }
        }

        /// Asks for the constraints to be updated.
        public struct Constraints: NSViewInvalidating {
            public init() {}
            public func invalidate(view: NSView) { view.needsUpdateConstraints = true }
        }

        /// Asks the view to recompute its intrinsic content size.
        public struct IntrinsicContentSize: NSViewInvalidating {
            public init() {}
            public func invalidate(view: NSView) { view.invalidateIntrinsicContentSize() }
        }

        /// Asks the system to save the view's restorable state again.
        public struct RestorableState: NSViewInvalidating {
            public init() {}
            public func invalidate(view: NSView) { view.invalidateRestorableState() }
        }

        /// Both invalidations, for a change that affects two aspects of a view.
        public struct Tuple<Invalidation1: NSViewInvalidating, Invalidation2: NSViewInvalidating>: NSViewInvalidating {
            private let first: Invalidation1
            private let second: Invalidation2

            public init(_ invalidation1: Invalidation1, _ invalidation2: Invalidation2) {
                first = invalidation1
                second = invalidation2
            }

            public func invalidate(view: NSView) {
                first.invalidate(view: view)
                second.invalidate(view: view)
            }
        }
    }

    /// Invalidates the enclosing view each time the wrapped property changes.
    @propertyWrapper
    public struct Invalidating<Value: Equatable, InvalidationType: NSViewInvalidating> {
        private var storage: Value
        private let invalidation: InvalidationType

        public init(wrappedValue: Value, _ invalidation: InvalidationType) {
            self.storage = wrappedValue
            self.invalidation = invalidation
        }

        // The compiler requires the plain accessor; reading or writing it directly skips the invalidation.
        public var wrappedValue: Value {
            get { return storage }
            set { storage = newValue }
        }

        public static subscript<EnclosingSelf: NSView>(
            _enclosingInstance observed: EnclosingSelf,
            wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
            storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Invalidating<Value, InvalidationType>>
        ) -> Value {
            get { return observed[keyPath: storageKeyPath].storage }
            set {
                let changed = observed[keyPath: storageKeyPath].storage != newValue
                observed[keyPath: storageKeyPath].storage = newValue
                if changed { observed[keyPath: storageKeyPath].invalidation.invalidate(view: observed) }
            }
        }

        public init<I1: NSViewInvalidating, I2: NSViewInvalidating>(wrappedValue: Value, _ invalidation1: I1, _ invalidation2: I2)
            where InvalidationType == Invalidations.Tuple<I1, I2> {
            self.init(wrappedValue: wrappedValue, Invalidations.Tuple(invalidation1, invalidation2))
        }

        public init<I1: NSViewInvalidating, I2: NSViewInvalidating, I3: NSViewInvalidating>(
            wrappedValue: Value, _ invalidation1: I1, _ invalidation2: I2, _ invalidation3: I3
        ) where InvalidationType == Invalidations.Tuple<Invalidations.Tuple<I1, I2>, I3> {
            self.init(wrappedValue: wrappedValue,
                      Invalidations.Tuple(Invalidations.Tuple(invalidation1, invalidation2), invalidation3))
        }

        public init<I1: NSViewInvalidating, I2: NSViewInvalidating, I3: NSViewInvalidating, I4: NSViewInvalidating>(
            wrappedValue: Value, _ invalidation1: I1, _ invalidation2: I2, _ invalidation3: I3, _ invalidation4: I4
        ) where InvalidationType == Invalidations.Tuple<Invalidations.Tuple<I1, I2>, Invalidations.Tuple<I3, I4>> {
            self.init(wrappedValue: wrappedValue,
                      Invalidations.Tuple(Invalidations.Tuple(invalidation1, invalidation2),
                                          Invalidations.Tuple(invalidation3, invalidation4)))
        }
    }
}
