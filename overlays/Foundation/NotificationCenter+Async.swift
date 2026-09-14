//===----------------------------------------------------------------------===//
//
// This source file is part of the darling-swift project.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
//===----------------------------------------------------------------------===//

// NotificationCenter.notifications(named:object:), the asynchronous sequence of posted notifications (macOS 12),
// written for Darling from Apple's public API documentation on top of the block-based observer API.

@_exported import Foundation // Clang module

extension NSNotificationCenter {
    /// An asynchronous sequence of the notifications posted with a name (and object) after it was created.
    public final class Notifications : AsyncSequence, @unchecked Sendable {
        public typealias Element = Notification

        private let stream: AsyncStream<Notification>
        private let center: NSNotificationCenter
        private let observer: Any

        fileprivate init(center: NSNotificationCenter, name: NSNotificationName, object: AnyObject?) {
            var continuation: AsyncStream<Notification>.Continuation!
            stream = AsyncStream(bufferingPolicy: .unbounded) { continuation = $0 }
            self.center = center
            let yield = continuation!
            observer = center.addObserver(forName: name.rawValue, object: object, queue: nil) { notification in
                if let notification = notification {
                    yield.yield(notification as Notification)
                }
            }
        }

        deinit {
            center.removeObserver(observer)
        }

        public struct Iterator : AsyncIteratorProtocol {
            // Keeps the sequence, and with it the observer, alive while iterating.
            private let sequence: Notifications
            private var base: AsyncStream<Notification>.Iterator

            fileprivate init(_ sequence: Notifications) {
                self.sequence = sequence
                base = sequence.stream.makeAsyncIterator()
            }

            public mutating func next() async -> Notification? {
                return await base.next()
            }
        }

        public func makeAsyncIterator() -> Iterator {
            return Iterator(self)
        }
    }

    public func notifications(named name: NSNotificationName, object: AnyObject? = nil) -> Notifications {
        return Notifications(center: self, name: name, object: object)
    }
}
