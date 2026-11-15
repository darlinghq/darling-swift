// Copyright (C) 2026 Lubos Dolezel
//
// Publishers.CollectByTime and Publisher.collect(_:options:), written from Combine's public documentation:
// the publisher gathers upstream values into arrays and publishes an array on every stride of the scheduler
// (TimeGroupingStrategy.byTime) or on every stride or when the array reaches the given size
// (TimeGroupingStrategy.byTimeOrCount). When the upstream finishes, the values collected so far are published
// before the completion; when it fails, the failure is forwarded and the collected values are dropped. The
// demand and delivery rules the documentation does not give follow macOS (see the QUIRK note on Inner).

// swiftlint:disable generic_type_name

extension Publisher {

    /// Collects elements by a given strategy, and emits a single array of the collection.
    ///
    /// If the upstream publisher finishes before the strategy publishes the collected elements, this publisher
    /// sends an array of everything it received (which may be fewer elements than a count in the strategy), then
    /// finishes. If the upstream fails, this publisher forwards the failure instead of the collected elements.
    ///
    /// - Parameters:
    ///   - strategy: The strategy with which to collect and publish elements.
    ///   - options: Scheduler options to use for the strategy.
    /// - Returns: A publisher that collects elements by a given strategy, and emits a single array of the
    ///   collection.
    public func collect<S: Scheduler>(
        _ strategy: Publishers.TimeGroupingStrategy<S>,
        options: S.SchedulerOptions? = nil
    ) -> Publishers.CollectByTime<Self, S> {
        return .init(upstream: self, strategy: strategy, options: options)
    }
}

extension Publishers {

    /// A strategy for collecting received elements.
    public enum TimeGroupingStrategy<Context: Scheduler> {

        /// A grouping that collects and periodically publishes items.
        case byTime(Context, Context.SchedulerTimeType.Stride)

        /// A grouping that collects and publishes items periodically or when a buffer reaches a maximum size.
        case byTimeOrCount(Context, Context.SchedulerTimeType.Stride, Int)
    }

    /// A publisher that buffers and periodically publishes its items.
    public struct CollectByTime<Upstream: Publisher, Context: Scheduler>: Publisher {

        public typealias Output = [Upstream.Output]

        public typealias Failure = Upstream.Failure

        /// The publisher that this publisher receives elements from.
        public let upstream: Upstream

        /// The strategy with which to collect and publish elements.
        public let strategy: Publishers.TimeGroupingStrategy<Context>

        /// `Scheduler` options to use for the strategy.
        public let options: Context.SchedulerOptions?

        public init(upstream: Upstream,
                    strategy: Publishers.TimeGroupingStrategy<Context>,
                    options: Context.SchedulerOptions?) {
            self.upstream = upstream
            self.strategy = strategy
            self.options = options
        }

        public func receive<Downstream: Subscriber>(subscriber: Downstream)
            where Downstream.Input == [Upstream.Output], Downstream.Failure == Upstream.Failure
        {
            let inner = Inner(strategy: strategy, options: options, downstream: subscriber)
            upstream.subscribe(inner)
        }
    }
}

extension Publishers.CollectByTime {
    // QUIRK: the demand, delivery and ordering rules of this operator are not documented; they follow what macOS
    // does, observed black-box on macOS 26.7.3 x86_64 with a virtual-time scheduler
    // (tier 2). In summary:
    //  - the timer is created (first firing one stride after now) when the upstream subscription arrives, before
    //    the downstream is given its subscription; it keeps running after a count-triggered array;
    //  - byTime: a downstream request is forwarded upstream as it is and every received element requests one more
    //    element; byTimeOrCount: a request for n arrays requests n * count elements and nothing more;
    //    with no downstream demand nothing is requested from the upstream;
    //  - a stride publishes the whole buffer straight from the timer, if it is not empty and the downstream has
    //    demand (otherwise the elements wait for a later stride); no empty arrays;
    //  - a full buffer (byTimeOrCount), and the completion, are delivered through scheduler.schedule(options:);
    //  - a normal completion publishes the pending elements (regardless of demand) and then the completion, each
    //    in its own scheduled call; a failure is delivered the same way and the pending elements are dropped;
    //  - a count below 1 publishes every element on its own.
    // Test: combine_collect_by_time.swift (the checks named "QUIRK").
    private final class Inner<Downstream: Subscriber>
        : Subscriber,
          Subscription,
          CustomStringConvertible,
          CustomReflectable,
          CustomPlaygroundDisplayConvertible
        where Downstream.Input == [Upstream.Output], Downstream.Failure == Upstream.Failure
    {
        typealias Input = Upstream.Output
        typealias Failure = Upstream.Failure

        private enum State {
            case awaitingSubscription(Downstream)
            case subscribed(Subscription, Downstream)
            case terminal
        }

        private let lock = UnfairLock.allocate()
        private let downstreamLock = UnfairRecursiveLock.allocate()
        private let scheduler: Context
        private let stride: Context.SchedulerTimeType.Stride
        private let maxCount: Int?
        private let options: Context.SchedulerOptions?

        private var state: State
        private var buffer: [Input] = []
        private var demand: Subscribers.Demand = .none
        private var timer: Cancellable?
        private var finishing = false

        init(strategy: Publishers.TimeGroupingStrategy<Context>,
             options: Context.SchedulerOptions?,
             downstream: Downstream) {
            switch strategy {
            case let .byTime(scheduler, stride):
                self.scheduler = scheduler
                self.stride = stride
                self.maxCount = nil
            case let .byTimeOrCount(scheduler, stride, count):
                self.scheduler = scheduler
                self.stride = stride
                self.maxCount = Swift.max(count, 1)
            }
            self.options = options
            self.state = .awaitingSubscription(downstream)
        }

        deinit {
            lock.deallocate()
            downstreamLock.deallocate()
        }

        func receive(subscription: Subscription) {
            lock.lock()
            guard case let .awaitingSubscription(downstream) = state else {
                lock.unlock()
                subscription.cancel()
                return
            }
            state = .subscribed(subscription, downstream)
            lock.unlock()

            let newTimer = scheduler.schedule(after: scheduler.now.advanced(by: stride),
                                              interval: stride,
                                              tolerance: scheduler.minimumTolerance,
                                              options: options) { [weak self] in
                self?.strideElapsed()
            }
            lock.lock()
            if case .subscribed = state {
                timer = newTimer
                lock.unlock()
            } else {
                lock.unlock()
                newTimer.cancel()
            }

            downstreamLock.lock()
            downstream.receive(subscription: self)
            downstreamLock.unlock()
        }

        func receive(_ input: Input) -> Subscribers.Demand {
            lock.lock()
            guard case .subscribed = state, !finishing else {
                lock.unlock()
                return .none
            }
            buffer.append(input)
            let full = maxCount.map { buffer.count >= $0 } ?? false
            lock.unlock()
            if full {
                scheduler.schedule(options: options) { [weak self] in
                    self?.publishFullBuffer()
                }
            }
            return maxCount == nil ? .max(1) : .none
        }

        func receive(completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard case .subscribed = state, !finishing else {
                lock.unlock()
                return
            }
            finishing = true
            let oldTimer = timer.take()
            lock.unlock()
            oldTimer?.cancel()
            scheduler.schedule(options: options) { [weak self] in
                self?.publishRemainder(completion)
            }
        }

        private func strideElapsed() {
            lock.lock()
            guard case let .subscribed(_, downstream) = state, !finishing,
                  !buffer.isEmpty, demand > .none else {
                lock.unlock()
                return
            }
            let chunk = takeChunk()
            lock.unlock()
            deliver(chunk, to: downstream)
        }

        private func publishFullBuffer() {
            lock.lock()
            guard case let .subscribed(_, downstream) = state, !finishing,
                  let maxCount = maxCount, buffer.count >= maxCount else {
                lock.unlock()
                return
            }
            let chunk = takeChunk()
            lock.unlock()
            deliver(chunk, to: downstream)
        }

        /// Called with the lock held. A byTimeOrCount array never holds more than the count.
        private func takeChunk() -> [Input] {
            let size = maxCount.map { Swift.min($0, buffer.count) } ?? buffer.count
            let chunk = Array(buffer.prefix(size))
            buffer.removeFirst(size)
            return chunk
        }

        private func deliver(_ chunk: [Input], to downstream: Downstream) {
            lock.lock()
            if demand > .none, demand != .unlimited { demand -= 1 }
            lock.unlock()
            downstreamLock.lock()
            let newDemand = downstream.receive(chunk)
            downstreamLock.unlock()
            if newDemand > .none {
                lock.lock()
                demand += newDemand
                lock.unlock()
            }
        }

        private func publishRemainder(_ completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard case let .subscribed(_, downstream) = state else {
                lock.unlock()
                return
            }
            let remainder = buffer.take()
            lock.unlock()
            if case .finished = completion, !remainder.isEmpty {
                // The remainder and the completion are separate scheduled calls.
                deliver(remainder, to: downstream)
                scheduler.schedule(options: options) { [weak self] in
                    self?.finish(completion)
                }
            } else {
                finish(completion)
            }
        }

        private func finish(_ completion: Subscribers.Completion<Failure>) {
            lock.lock()
            guard case let .subscribed(_, downstream) = state else {
                lock.unlock()
                return
            }
            state = .terminal
            lock.unlock()
            downstreamLock.lock()
            downstream.receive(completion: completion)
            downstreamLock.unlock()
        }

        func request(_ demand: Subscribers.Demand) {
            guard demand > .none else { return }
            lock.lock()
            guard case let .subscribed(subscription, _) = state else {
                lock.unlock()
                return
            }
            self.demand += demand
            lock.unlock()
            if let maxCount = maxCount, demand != .unlimited {
                let (elements, overflow) = demand.max!.multipliedReportingOverflow(by: maxCount)
                subscription.request(overflow ? .unlimited : .max(elements))
            } else {
                subscription.request(demand)
            }
        }

        func cancel() {
            lock.lock()
            let subscription: Subscription?
            if case let .subscribed(existing, _) = state {
                subscription = existing
            } else {
                subscription = nil
            }
            state = .terminal
            buffer = []
            let oldTimer = timer.take()
            lock.unlock()
            oldTimer?.cancel()
            subscription?.cancel()
        }

        var description: String { return "CollectByTime" }

        var customMirror: Mirror { return Mirror(self, children: EmptyCollection()) }

        var playgroundDescription: Any { return description }
    }
}
