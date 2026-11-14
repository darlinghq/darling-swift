// NSApplication.ShouldBeginSuppressingHighDynamicRangeContent and .ShouldEndSuppressingHighDynamicRangeContent (macOS 26),
// the message types whose `name` is the notification posted when the app should stop or resume showing HDR content.
//
// Provenance. Names: App Store imports both `name` getters (rung 5, llvm-nm -u -m). Declarations: Apple's public
// documentation, https://developer.apple.com/documentation/appkit/nsapplication/
// shouldbeginsuppressinghighdynamicrangecontent (and ...end...): structs nested in NSApplication, macOS 26.0, conforming to
// MainActorMessage and SendableMetatype. The notification names: observed on a real Mac running macOS 26.1, where the
// constants NSApplicationShouldBeginSuppressingHighDynamicRangeContentNotification and
// NSApplicationShouldEndSuppressingHighDynamicRangeContentNotification exist and each string equals its own symbol name.
// Nothing posts these notifications under Darling; the overlay only supplies the names.
// Left out: the MainActorMessage and SendableMetatype conformances, because Darling's Foundation overlay has no
// NotificationCenter.MainActorMessage; no app named here imports a conformance descriptor for them (their `name`
// getters are all that App Store binds).

@_exported import Foundation
#if DARLING_APPKIT_CLANG_MODULE
@_exported import AppKit
#else
import _DarlingAppKitShims
#endif

extension NSApplication {
    /// Posted when the app should stop showing high dynamic range content.
    public struct ShouldBeginSuppressingHighDynamicRangeContent {
        public static var name: Notification.Name {
            return Notification.Name("NSApplicationShouldBeginSuppressingHighDynamicRangeContentNotification")
        }
    }

    /// Posted when the app may show high dynamic range content again.
    public struct ShouldEndSuppressingHighDynamicRangeContent {
        public static var name: Notification.Name {
            return Notification.Name("NSApplicationShouldEndSuppressingHighDynamicRangeContentNotification")
        }
    }
}
