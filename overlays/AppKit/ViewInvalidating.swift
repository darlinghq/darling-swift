// NSView.Invalidating (macOS 12), the property wrapper that invalidates a view when a property changes, the
// NSViewInvalidating protocol and the Invalidations types that conform to it.
//
// Provenance. Declarations: Apple's public documentation,
// https://developer.apple.com/documentation/appkit/nsview/invalidating (`<Value: Equatable, InvalidationType:
// NSViewInvalidating>`, initializers for one to ten invalidations, where several are nested Tuples:
// `Tuple<Tuple<I1, I2>, I3>` for three, `Tuple<Tuple<I1, I2>, Tuple<I3, I4>>` for four),
// .../nsview/invalidations (Constraints, Display, IntrinsicContentSize, Layout, RestorableState, Tuple<Invalidation1,
// Invalidation2>) and .../nsviewinvalidating (`invalidate(view:)`). Each invalidation sets the flag or calls the method
// its name says (needsLayout, needsDisplay, needsUpdateConstraints, invalidateIntrinsicContentSize,
// invalidateRestorableState).
// Layout that cannot matter: every type here is a non-frozen struct or an enum namespace, under library evolution.
// Behaviour (black-box probe on macOS 26.7.3): the wrapper invalidates only when the new value differs from the old
// one, and each kind of invalidation does what its name says. The order in which a Tuple applies its two
// invalidations could not be observed; it applies the first and then the second. The declarations, including
// the protocol's single requirement, were compared with the macOS 26 SDK's Swift module interface (declarations only).

@_exported import Foundation

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
            // Darling's AppKit has no state restoration and its NSResponder does not declare
            // -invalidateRestorableState yet, so the message is sent only to a view that implements it.
            public func invalidate(view: NSView) {
                let selector = Selector(("invalidateRestorableState"))
                if view.responds(to: selector) { _ = view.perform(selector) }
            }
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

        // The compiler requires the plain accessor; the enclosing-instance subscript below is what runs for a property of
        // an NSView subclass, and it is unavailable to direct use as in the macOS SDK.
        @available(*, unavailable, message: "@NSView.Invalidating can only be used on subclasses of NSView")
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

        public init<I1: NSViewInvalidating, I2: NSViewInvalidating, I3: NSViewInvalidating, I4: NSViewInvalidating, I5: NSViewInvalidating>(
            wrappedValue: Value, _ invalidation1: I1, _ invalidation2: I2, _ invalidation3: I3, _ invalidation4: I4, _ invalidation5: I5
        ) where InvalidationType == Invalidations.Tuple<Invalidations.Tuple<Invalidations.Tuple<I1, I2>, Invalidations.Tuple<I3, I4>>, I5> {
            self.init(wrappedValue: wrappedValue, Invalidations.Tuple(Invalidations.Tuple(Invalidations.Tuple(invalidation1, invalidation2), Invalidations.Tuple(invalidation3, invalidation4)), invalidation5))
        }

        public init<I1: NSViewInvalidating, I2: NSViewInvalidating, I3: NSViewInvalidating, I4: NSViewInvalidating, I5: NSViewInvalidating, I6: NSViewInvalidating>(
            wrappedValue: Value, _ invalidation1: I1, _ invalidation2: I2, _ invalidation3: I3, _ invalidation4: I4, _ invalidation5: I5, _ invalidation6: I6
        ) where InvalidationType == Invalidations.Tuple<Invalidations.Tuple<Invalidations.Tuple<I1, I2>, Invalidations.Tuple<I3, I4>>, Invalidations.Tuple<I5, I6>> {
            self.init(wrappedValue: wrappedValue, Invalidations.Tuple(Invalidations.Tuple(Invalidations.Tuple(invalidation1, invalidation2), Invalidations.Tuple(invalidation3, invalidation4)), Invalidations.Tuple(invalidation5, invalidation6)))
        }

        public init<I1: NSViewInvalidating, I2: NSViewInvalidating, I3: NSViewInvalidating, I4: NSViewInvalidating, I5: NSViewInvalidating, I6: NSViewInvalidating, I7: NSViewInvalidating>(
            wrappedValue: Value, _ invalidation1: I1, _ invalidation2: I2, _ invalidation3: I3, _ invalidation4: I4, _ invalidation5: I5, _ invalidation6: I6, _ invalidation7: I7
        ) where InvalidationType == Invalidations.Tuple<Invalidations.Tuple<Invalidations.Tuple<I1, I2>, Invalidations.Tuple<I3, I4>>, Invalidations.Tuple<Invalidations.Tuple<I5, I6>, I7>> {
            self.init(wrappedValue: wrappedValue, Invalidations.Tuple(Invalidations.Tuple(Invalidations.Tuple(invalidation1, invalidation2), Invalidations.Tuple(invalidation3, invalidation4)), Invalidations.Tuple(Invalidations.Tuple(invalidation5, invalidation6), invalidation7)))
        }

        public init<I1: NSViewInvalidating, I2: NSViewInvalidating, I3: NSViewInvalidating, I4: NSViewInvalidating, I5: NSViewInvalidating, I6: NSViewInvalidating, I7: NSViewInvalidating, I8: NSViewInvalidating>(
            wrappedValue: Value, _ invalidation1: I1, _ invalidation2: I2, _ invalidation3: I3, _ invalidation4: I4, _ invalidation5: I5, _ invalidation6: I6, _ invalidation7: I7, _ invalidation8: I8
        ) where InvalidationType == Invalidations.Tuple<Invalidations.Tuple<Invalidations.Tuple<I1, I2>, Invalidations.Tuple<I3, I4>>, Invalidations.Tuple<Invalidations.Tuple<I5, I6>, Invalidations.Tuple<I7, I8>>> {
            self.init(wrappedValue: wrappedValue, Invalidations.Tuple(Invalidations.Tuple(Invalidations.Tuple(invalidation1, invalidation2), Invalidations.Tuple(invalidation3, invalidation4)), Invalidations.Tuple(Invalidations.Tuple(invalidation5, invalidation6), Invalidations.Tuple(invalidation7, invalidation8))))
        }

        public init<I1: NSViewInvalidating, I2: NSViewInvalidating, I3: NSViewInvalidating, I4: NSViewInvalidating, I5: NSViewInvalidating, I6: NSViewInvalidating, I7: NSViewInvalidating, I8: NSViewInvalidating, I9: NSViewInvalidating>(
            wrappedValue: Value, _ invalidation1: I1, _ invalidation2: I2, _ invalidation3: I3, _ invalidation4: I4, _ invalidation5: I5, _ invalidation6: I6, _ invalidation7: I7, _ invalidation8: I8, _ invalidation9: I9
        ) where InvalidationType == Invalidations.Tuple<Invalidations.Tuple<Invalidations.Tuple<Invalidations.Tuple<I1, I2>, Invalidations.Tuple<I3, I4>>, Invalidations.Tuple<Invalidations.Tuple<I5, I6>, Invalidations.Tuple<I7, I8>>>, I9> {
            self.init(wrappedValue: wrappedValue, Invalidations.Tuple(Invalidations.Tuple(Invalidations.Tuple(Invalidations.Tuple(invalidation1, invalidation2), Invalidations.Tuple(invalidation3, invalidation4)), Invalidations.Tuple(Invalidations.Tuple(invalidation5, invalidation6), Invalidations.Tuple(invalidation7, invalidation8))), invalidation9))
        }

        public init<I1: NSViewInvalidating, I2: NSViewInvalidating, I3: NSViewInvalidating, I4: NSViewInvalidating, I5: NSViewInvalidating, I6: NSViewInvalidating, I7: NSViewInvalidating, I8: NSViewInvalidating, I9: NSViewInvalidating, I10: NSViewInvalidating>(
            wrappedValue: Value, _ invalidation1: I1, _ invalidation2: I2, _ invalidation3: I3, _ invalidation4: I4, _ invalidation5: I5, _ invalidation6: I6, _ invalidation7: I7, _ invalidation8: I8, _ invalidation9: I9, _ invalidation10: I10
        ) where InvalidationType == Invalidations.Tuple<Invalidations.Tuple<Invalidations.Tuple<Invalidations.Tuple<I1, I2>, Invalidations.Tuple<I3, I4>>, Invalidations.Tuple<Invalidations.Tuple<I5, I6>, Invalidations.Tuple<I7, I8>>>, Invalidations.Tuple<I9, I10>> {
            self.init(wrappedValue: wrappedValue, Invalidations.Tuple(Invalidations.Tuple(Invalidations.Tuple(Invalidations.Tuple(invalidation1, invalidation2), Invalidations.Tuple(invalidation3, invalidation4)), Invalidations.Tuple(Invalidations.Tuple(invalidation5, invalidation6), Invalidations.Tuple(invalidation7, invalidation8))), Invalidations.Tuple(invalidation9, invalidation10)))
        }
    }
}
