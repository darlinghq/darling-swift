// GroupActivities: the public API surface Apple's closed framework exports, declared so that the
// mangled symbol names match what apps bind. The shape here was recovered from the mangled names
// an app imports, not from Apple sources. See overlays/README.md.

import Combine
import Foundation

// SharePlay needs a coordination service that Darling does not have, so this framework answers as a device that is
// not in a FaceTime call: nothing is eligible, no activity can be activated, and no session is ever delivered. A
// GroupSession cannot be created by clients (its initializer is private), so the calls that need one never run;
// the members still behave sensibly instead of trapping should that change.
private let notAvailable = CocoaError(.featureUnsupported)

public struct GroupActivityMetadata {
    public struct ActivityType {
        private init() {}
        public static var generic: ActivityType { ActivityType() }
    }

    public var type: ActivityType
    public var title: String?

    public init() {
        self.type = .generic
        self.title = nil
    }
}

public struct Participant: Hashable {
    private init() {}
}

public enum Participants {
    case all
    case only(Set<Participant>)
}

public protocol GroupActivity: Encodable, Decodable {
    static var activityIdentifier: String { get }
    var metadata: GroupActivityMetadata { get }
    static func _identifiable(by: String) -> Bool
    static func _identifiable(by: String, staticIdentifier: String?) -> Bool
}

public extension GroupActivity {
    static var activityIdentifier: String { String(reflecting: Self.self) }

    static func _identifiable(by identifier: String) -> Bool {
        identifier == activityIdentifier
    }

    static func _identifiable(by identifier: String, staticIdentifier: String?) -> Bool {
        identifier == (staticIdentifier ?? activityIdentifier)
    }

    // Returns false rather than throwing: "not activated" is this API's own way of saying no, and
    // a caller that checked isEligibleForGroupSession first already expects it.
    func activate() async throws -> Bool { false }

    static func sessions() -> GroupSession<Self>.Sessions { GroupSession<Self>.Sessions() }
}

// The classes below must stay final: a non-final member is emitted private_extern and reached via a
// Tj thunk, which ld64 demotes to local. Apps bind direct symbols and no Tj, so dropping final still
// builds and links but exports 44 of 53 names, and the app then fails to load with no clue why.
public final class GroupSession<A: GroupActivity> {
    public enum State {
        case waiting
        case joined
        case invalidated(reason: Error)
    }

    public struct Sessions: AsyncSequence {
        public typealias Element = GroupSession<A>

        public struct Iterator: AsyncIteratorProtocol {
            // Apple's sessions() never terminates, it just never yields. Returning nil would report
            // a completion the real framework cannot emit, letting a caller run post-loop teardown
            // that is unreachable on macOS. Cancellation is the only real exit, so honour that only.
            public mutating func next() async -> GroupSession<A>? {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
                }
                return nil
            }
        }

        public func makeAsyncIterator() -> Iterator { Iterator() }
    }

    @Published public var state: State
    @Published public var activeParticipants: Set<Participant>

    // No session can be created, so this exists only to give the properties valid values: a session that has
    // already been invalidated and has no participants.
    private init() {
        state = .invalidated(reason: notAvailable)
        activeParticipants = []
    }

    // There is no group to join or leave.
    public func join() {}
    public func leave() {}
}

public final class GroupStateObserver {
    public init() {}
    public var isEligibleForGroupSession: Bool { false }
}

public final class GroupSessionMessenger {
    public struct MessageContext {}

    public struct Messages<M: Codable>: AsyncSequence {
        public typealias Element = (M, MessageContext)

        public struct Iterator: AsyncIteratorProtocol {
            // No messages ever arrive: the sequence is empty and finishes at once.
            public mutating func next() async -> (M, MessageContext)? { nil }
        }

        public func makeAsyncIterator() -> Iterator { Iterator() }
    }

    // A messenger needs a session, and none can exist; it keeps nothing.
    public init<A: GroupActivity>(session: GroupSession<A>) {}

    // Nobody is in the session to receive the message.
    public func send<M: Codable>(_ message: M, to participants: Participants) async throws {
        throw notAvailable
    }

    public func messages<M: Codable>(of type: M.Type) -> Messages<M> { Messages<M>() }
}
