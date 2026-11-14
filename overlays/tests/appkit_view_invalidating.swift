// NSView.Invalidating, NSViewInvalidating and the Invalidations types from the AppKit overlay, under Darling.
import AppKit
import _DarlingAppKitShims

var failures = 0
func check(_ condition: Bool, _ label: String) {
    print(condition ? "ok:" : "FAIL:", label)
    if !condition { failures += 1 }
}

final class Probe: NSView {
    var invalidations = 0
    struct Count: NSViewInvalidating {
        func invalidate(view: NSView) { (view as! Probe).invalidations += 1 }
    }
    @NSView.Invalidating(Count()) var label = "a"
    @NSView.Invalidating(NSView.Invalidations.Layout(), NSView.Invalidations.Display()) var twoKinds = 1
    @NSView.Invalidating(NSView.Invalidations.Layout(), NSView.Invalidations.Display(), NSView.Invalidations.IntrinsicContentSize())
    var threeKinds = 1
    @NSView.Invalidating(NSView.Invalidations.Layout(), NSView.Invalidations.Display(),
                         NSView.Invalidations.Constraints(), NSView.Invalidations.RestorableState())
    var fourKinds = 1
    // The form the documentation shows.
    @NSView.Invalidating(.display, .layout) var shorthand = 1
    @NSView.Invalidating(.intrinsicContentSize) var oneShorthand = 1
}

let probe = Probe()
check(probe.label == "a" && probe.invalidations == 0, "reading does not invalidate")
probe.label = "b"
check(probe.label == "b" && probe.invalidations == 1, "writing a new value invalidates once")
probe.label = "b"
check(probe.invalidations == 1, "writing the same value does not invalidate")

probe.needsLayout = false
NSView.Invalidations.Layout().invalidate(view: probe)
check(probe.needsLayout, "Layout marks the view as needing layout")
probe.needsDisplay = false
NSView.Invalidations.Display().invalidate(view: probe)
check(probe.needsDisplay, "Display marks the view as needing display")
probe.needsUpdateConstraints = false
NSView.Invalidations.Constraints().invalidate(view: probe)
check(probe.needsUpdateConstraints, "Constraints marks the view as needing a constraint update")
NSView.Invalidations.IntrinsicContentSize().invalidate(view: probe)
NSView.Invalidations.RestorableState().invalidate(view: probe)
check(true, "IntrinsicContentSize and RestorableState send their messages")

probe.needsLayout = false
probe.needsDisplay = false
probe.twoKinds = 2
check(probe.needsLayout && probe.needsDisplay, "two invalidations: both fire on a change")
probe.needsLayout = false
probe.needsDisplay = false
probe.twoKinds = 2
check(!probe.needsLayout && !probe.needsDisplay, "two invalidations: neither fires without a change")
probe.needsLayout = false
probe.needsDisplay = false
probe.threeKinds = 2
check(probe.needsLayout && probe.needsDisplay, "three invalidations fire")
probe.needsLayout = false
probe.needsDisplay = false
probe.needsUpdateConstraints = false
probe.fourKinds = 2
check(probe.needsLayout && probe.needsDisplay && probe.needsUpdateConstraints, "four invalidations fire")

probe.needsLayout = false
probe.needsDisplay = false
probe.shorthand = 2
check(probe.needsLayout && probe.needsDisplay, "the documented .display, .layout shorthand")
check(NSView.Invalidations.Constraints.constraints is NSView.Invalidations.Constraints
      && NSView.Invalidations.RestorableState.restorableState is NSView.Invalidations.RestorableState, "static members")

let tuple = NSView.Invalidations.Tuple(NSView.Invalidations.Layout(), NSView.Invalidations.Display())
probe.needsLayout = false
probe.needsDisplay = false
tuple.invalidate(view: probe)
check(probe.needsLayout && probe.needsDisplay, "Tuple invalidates both")

if failures != 0 { exit(1) }
