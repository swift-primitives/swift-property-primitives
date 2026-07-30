public import Property_Primitive

#if !hasFeature(Embedded)
    public import Synchronization
#else
    /// Unsynchronized stand-in for `Synchronization.Mutex` on Embedded Swift,
    /// where the `Synchronization` module exposes no `Mutex`.
    ///
    /// Mirrors the established ecosystem position in `Async.Mutex`
    /// (`swift-async-primitives`, `Sources/Async Mutex Primitives`): embedded
    /// targets have no OS kernel and typically no threading, so the lock
    /// compiles to a no-op while preserving the `withLock` shape. Declared
    /// here rather than taken as a dependency — `swift-async-primitives` sits
    /// far above this package in the graph.
    ///
    /// A `final class` rather than a `struct` because `State._storage` is
    /// `let`-bound and `withLock` needs `inout` access to the payload.
    ///
    /// ## Safety Invariant (Embedded only)
    /// Mutual exclusion is provided by the single-threaded embedded execution
    /// model, not by this type. The `@unchecked Sendable` conformance on
    /// `Property.Consume.State` is correspondingly weaker under Embedded: it
    /// rests on the absence of concurrent threads, whereas the non-embedded
    /// build enforces it with a real lock. Do not lift this type into a
    /// multi-threaded configuration.
    @usableFromInline
    internal final class _UnsynchronizedBox<Value: ~Copyable>: @unchecked Sendable {
        @usableFromInline
        internal var _value: Value

        @inlinable
        internal init(_ value: consuming sending Value) {
            self._value = value
        }

        @inlinable
        internal func withLock<Result: ~Copyable, E: Swift.Error>(
            _ body: (inout sending Value) throws(E) -> sending Result
        ) throws(E) -> sending Result {
            try body(&_value)
        }
    }
#endif

extension Property.Consume where Base: Copyable {
    /// ## Safety Invariant (Category A — synchronized)
    /// `State` is a `final class` shared across `Consume` instances via
    /// `init(state:)`, so its mutable fields must be synchronized rather than
    /// merely documented. `_storage` is a `Synchronization.Mutex<Storage>`
    /// (`_UnsynchronizedBox<Storage>` under Embedded, where mutual exclusion
    /// comes from the single-threaded execution model instead — see above);
    /// every read and write of the wrapped base and the consumed flag flows
    /// through `_storage.withLock`, and `consume()` performs its
    /// check-then-set-then-clear sequence inside a single lock acquisition.
    /// Two `Consume` instances sharing one `State` (e.g. one calling
    /// `consume()` while another calls `borrow()`/`isConsumed`) therefore
    /// cannot observe a torn base/consumed pair or race on the transition —
    /// the prior `@unchecked Sendable` claim relied on non-atomic field
    /// access and was unsound for that sharing pattern.
    // TRACKING: Experiments/property-consuming-value-state (Option C REFUTED
    //      2026-04-21, release-mode SIL crash on 6.3.1); companion benchmark
    //      Experiments/property-consuming-state-allocation-benchmark (no perf
    //      upside, REFUTED). A `~Copyable` value-type State remains blocked
    //      on the upstream EarlyPerfInliner crash; the Mutex-guarded
    //      reference type below is the sound fix within that constraint.
    /// State tracker for conditional restoration.
    public final class State {
        /// The synchronized storage: the wrapped base value (`nil` once
        /// consumed) and the consumed flag, guarded by one lock so both
        /// fields transition together.
        @usableFromInline
        internal struct Storage {
            @usableFromInline
            internal var base: Base?

            @usableFromInline
            internal var consumed: Bool

            @usableFromInline
            internal init(base: consuming sending Base) {
                self.base = base
                self.consumed = false
            }
        }

        #if !hasFeature(Embedded)
            @usableFromInline
            internal let _storage: Mutex<Storage>
        #else
            @usableFromInline
            internal let _storage: _UnsynchronizedBox<Storage>
        #endif

        /// Creates state wrapping the given base value.
        @inlinable
        public init(_ base: consuming sending Base) {
            #if !hasFeature(Embedded)
                self._storage = Mutex(Storage(base: base))
            #else
                self._storage = _UnsynchronizedBox(Storage(base: base))
            #endif
        }
    }
}

extension Property.Consume.State {
    /// Whether the base has been consumed.
    @inlinable
    public var isConsumed: Bool {
        _storage.withLock { $0.consumed }
    }

    /// Borrows the base value for read access.
    ///
    /// Returns `nil` if already consumed.
    @inlinable
    public func borrow() -> Base? {
        _storage.withLock { $0.base }
    }

    /// Atomically consumes the base value: observes and clears `base` and
    /// sets `consumed` inside a single lock acquisition, so a concurrent
    /// `borrow()`/`isConsumed`/`consume()` from a `Consume` instance sharing
    /// this `State` cannot interleave with the transition.
    ///
    /// Returns `nil` if already consumed.
    @inlinable
    package func consume() -> Base? {
        _storage.withLock { storage in
            guard let base = storage.base else { return nil }
            storage.consumed = true
            storage.base = nil
            return base
        }
    }

    /// Atomically returns the base value if the consuming path was not
    /// taken, `nil` if consumed — the consumed check and the base read
    /// happen inside a single lock acquisition.
    @inlinable
    package func restore() -> Base? {
        _storage.withLock { storage in
            storage.consumed ? nil : storage.base
        }
    }
}

// SAFETY: the `where Base: Sendable` clause is load-bearing, not decorative:
// SAFETY: `Mutex<Storage>` is unconditionally Sendable, but `borrow()` hands a
// SAFETY: copy of `base` out of the lock — without this clause a non-Sendable
// SAFETY: `Base` could cross isolation regions through that copy with zero
// SAFETY: compiler signal. Do not drop or widen the constraint.
extension Property.Consume.State: @unchecked Sendable where Base: Sendable {}
