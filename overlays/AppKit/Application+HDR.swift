// NSApplication.ShouldBeginSuppressingHighDynamicRangeContent and .ShouldEndSuppressingHighDynamicRangeContent (macOS 26),
// the message types whose `name` is the notification posted when the app should stop or resume showing HDR content.
//
// Provenance. Declarations: Apple's public documentation,
// https://developer.apple.com/documentation/appkit/nsapplication/
// shouldbeginsuppressinghighdynamicrangecontent (and ...end...): structs nested in NSApplication, macOS 26.0, conforming to
// MainActorMessage and SendableMetatype; confirmed against the macOS 26 SDK's Swift module interface (declarations
// only). The notification names: on macOS 26.7.3 `name.rawValue` of each type equals NSApplicationShouldBegin... and
// NSApplicationShouldEnd...SuppressingHighDynamicRangeContentNotification, the constants' own names.
// Nothing posts these notifications under Darling; the overlay only supplies the names.
// Left out: the MainActorMessage and SendableMetatype conformances, because Darling's Foundation overlay has no
// NotificationCenter.MainActorMessage (only their `name`
// getters are provided).

@_exported import Foundation

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
