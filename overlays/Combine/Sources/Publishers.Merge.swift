//
//  Publishers.Merge.swift
//
//  Combine upstream publishers of the same output and failure types.
//

extension Publisher {

    /// Publishes values from either upstream as they arrive.
    public func merge<Other: Publisher>(with other: Other) -> Publishers.Merge<Self, Other>
        where Other.Output == Output, Other.Failure == Failure
    {
        return .init(self, other)
    }
}

extension Publishers {

    /// A publisher that interleaves elements from two upstream publishers.
    public struct Merge<A: Publisher, B: Publisher>: Publisher
        where A.Output == B.Output, A.Failure == B.Failure
    {
        public typealias Output = A.Output
        public typealias Failure = A.Failure

        public let a: A
        public let b: B

        public init(_ a: A, _ b: B) {
            self.a = a
            self.b = b
        }

        public func receive<Downstream: Subscriber>(subscriber: Downstream)
            where Downstream.Input == Output, Downstream.Failure == Failure
        {
            Publishers.MergeMany([a.eraseToAnyPublisher(), b.eraseToAnyPublisher()])
                .receive(subscriber: subscriber)
        }
    }

    /// A publisher that interleaves elements from any number of upstream publishers.
    public struct MergeMany<Upstream: Publisher>: Publisher {
        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure

        public let upstream: [Upstream]

        public init<S: Swift.Sequence>(_ upstream: S) where S.Element == Upstream {
            self.upstream = Array(upstream)
        }

        public init(_ upstream: Upstream...) {
            self.upstream = upstream
        }

        public func receive<Downstream: Subscriber>(subscriber: Downstream)
            where Downstream.Input == Output, Downstream.Failure == Failure
        {
            Publishers.Sequence<[Upstream], Failure>(sequence: upstream)
                .flatMap { $0 }
                .receive(subscriber: subscriber)
        }
    }
}
