public import Property_Primitive
public import Synchronization

extension Property.Consume where Base: Copyable {
    /// ## Safety Invariant (Category A — synchronized)
    /// `State` is a `final class` shared across `Consume` instances via
    /// `init(state:)`, so its mutable fields must be synchronized rather than
    /// merely documented. `_storage` is a `Synchronization.Mutex<Storage>`;
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

        @usableFromInline
        internal let _storage: Mutex<Storage>

        /// Creates state wrapping the given base value.
        @inlinable
        public init(_ base: consuming sending Base) {
            self._storage = Mutex(Storage(base: base))
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
    internal func consume() -> Base? {
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
    internal func restore() -> Base? {
        _storage.withLock { storage in
            storage.consumed ? nil : storage.base
        }
    }
}

extension Property.Consume.State: @unchecked Sendable where Base: Sendable {}
