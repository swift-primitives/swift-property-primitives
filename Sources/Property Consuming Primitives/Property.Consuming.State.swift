public import Property_Primitives_Core

extension Property.Consuming {
    // WORKAROUND: @unchecked Sendable on Property.Consuming.State.
    // WHY: `final class` with mutable stored properties (`var _base: Base?`,
    //      `var _consumed: Bool`) cannot be auto-verified as Sendable. The
    //      conformance is required so `Property.Consuming: Sendable where
    //      Base: Sendable` propagates through the reference-type State. The
    //      claim is CONDITIONAL on `Base: Sendable` (narrower than the prior
    //      unconditional annotation). Residual hazard: concurrent `consume()`
    //      from two Consuming instances sharing a single State via
    //      `init(state:)` is a data race on `_base`/`_consumed`; callers must
    //      avoid concurrent mutation of shared State.
    // WHEN TO REMOVE: Replace with a ~Copyable value-type State once the
    //      Swift SIL EarlyPerfInliner crash on `~Copyable` Consuming
    //      inlining is fixed upstream; alternatively, when Sendable inference
    //      directly verifies mutable-property final classes under conditional
    //      constraints.
    // TRACKING: Experiments/property-consuming-value-state (Option C REFUTED
    //      2026-04-21, release-mode SIL crash on 6.3.1); companion benchmark
    //      Experiments/property-consuming-state-allocation-benchmark (no perf
    //      upside, REFUTED).
    /// State tracker for conditional restoration.
    public final class State {
        /// The wrapped base value, or nil if already consumed.
        @usableFromInline
        internal var _base: Base?

        /// Whether the consuming path was taken.
        @usableFromInline
        internal var _consumed: Bool

        /// Creates state wrapping the given base value.
        @inlinable
        public init(_ base: consuming Base) {
            self._base = consume base
            self._consumed = false
        }

        /// Whether the base has been consumed.
        @inlinable
        public var isConsumed: Bool { _consumed }

        /// Borrows the base value for read access.
        ///
        /// Returns `nil` if already consumed.
        @inlinable
        public func borrow() -> Base? { _base }
    }
}

extension Property.Consuming.State: @unchecked Sendable where Base: Sendable {}
