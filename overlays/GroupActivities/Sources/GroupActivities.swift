// GroupActivities: the public API surface Apple's closed framework exports, declared so that the
// mangled symbol names match what apps bind. The shape here was recovered from the mangled names
// an app imports, not from Apple sources. See overlays/README.md.

import Combine

// Reaching any of these does not mean "SharePlay is unavailable"; it means this stub's API surface
// drifted from Apple's and something built a type that should be unbuildable. Say so explicitly.
private func unreachable(_ what: String) -> Never {
    fatalError("""
        GroupActivities: \(what) is unreachable. SharePlay needs a coordination daemon Darling \
        does not have, so this framework never creates a session. Reaching this means the stub \
        diverged from Apple's API; please report it with the app name.
        """)
}

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

    // Deliberately uninitialised: init traps, so these are never observed. They are not defaults,
    // and must not be treated as sane ones if this class ever becomes constructible.
    @Published public var state: State
    @Published public var activeParticipants: Set<Participant>

    private init() { unreachable("GroupSession") }

    public func join() { unreachable("GroupSession.join") }
    public func leave() { unreachable("GroupSession.leave") }
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
            // Unobservable: messages(of:) traps, so no Messages value exists. If that ever gains a
            // real implementation this nil becomes the same fabricated completion as Sessions above.
            public mutating func next() async -> (M, MessageContext)? { nil }
        }

        public func makeAsyncIterator() -> Iterator { Iterator() }
    }

    public init<A: GroupActivity>(session: GroupSession<A>) {
        unreachable("GroupSessionMessenger")
    }

    public func send<M: Codable>(_ message: M, to participants: Participants) async throws {
        unreachable("GroupSessionMessenger.send")
    }

    public func messages<M: Codable>(of type: M.Type) -> Messages<M> {
        unreachable("GroupSessionMessenger.messages")
    }
}
