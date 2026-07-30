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
    // TRACKING: Experiments/property-consuming-value-state (Option C REFUTED
    //      2026-04-21, release-mode SIL crash on 6.3.1); companion benchmark
    //      Experiments/property-consuming-state-allocation-benchmark (no perf
    //      upside, REFUTED). A `~Copyable` value-type State remains blocked
    //      on the upstream EarlyPerfInliner crash; the Mutex-guarded
    //      reference type below is the sound fix within that constraint.
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
    ///
    /// State tracker for conditional restoration.
    public final class State {
        /// The synchronized storage: the wrapped base value (`nil` once
        /// consumed) and the consumed flag, guarded by one lock so both
        /// fields transition together.
        ///
        /// ## Safety Invariant (Category A — synchronized)
        /// `@unchecked Sendable` unconditionally, including for a non-Sendable
        /// `Base`. `Storage` has exactly one use: the payload of the enclosing
        /// `State`'s `_storage` lock. Every read and write of both fields goes
        /// through `withLock`, so the lock — not `Base`'s own Sendability — is
        /// what serializes access to them.
        ///
        /// Reachability of the payload from a second isolation region is
        /// re-imposed one level up, by `State`'s conditional conformance
        /// (`@unchecked Sendable where Base: Sendable`, below): a `State` over
        /// a non-Sendable `Base` is not `Sendable`, so this `Storage` cannot be
        /// reached from another region at all. This conformance therefore
        /// asserts only what the lock already guarantees, and does not widen
        /// the surface that `State`'s load-bearing `where` clause guards.
        ///
        /// Declaring it here is what lets the initializers below take a plain
        /// `consuming Base` instead of `consuming sending Base` — see the
        /// ownership note on `init(_:)`.
        @usableFromInline
        internal struct Storage: @unchecked Sendable {
            @usableFromInline
            internal var base: Base?

            @usableFromInline
            internal var consumed: Bool

            @usableFromInline
            internal init(base: consuming Base) {
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
        ///
        /// ## Ownership
        /// The parameter is `consuming` but deliberately **not** `sending`.
        /// Nothing crosses an isolation boundary here: the `State` that comes
        /// out is `Sendable` only when `Base` is (see the conditional
        /// conformance at the bottom of this file), so for a non-Sendable
        /// `Base` it stays in the caller's region, merged with `base`'s. A
        /// `sending` requirement would instead demand a *disconnected*
        /// argument, which the canonical accessor pattern documented on
        /// ``Property/Consume`` can never supply — the `self` it wraps is
        /// task-isolated. The lock's own `sending` requirement is satisfied
        /// by `Storage`'s conformance above rather than pushed onto callers.
        @inlinable
        public init(_ base: consuming Base) {
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
    ///
    /// ## Safety
    /// Must keep returning a plain `Base?`. Never change this to `sending
    /// Base?` — that is fact 2 of the SAFETY note on `State`'s conditional
    /// `Sendable` conformance, below; it is the one edit that turns this type
    /// from sound to racy while every existing test keeps compiling.
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
    ///
    /// ## Safety
    /// Must keep returning a plain `Base?`, not `sending Base?` — see the
    /// note on `borrow()` above and fact 2 of the SAFETY note below.
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
    ///
    /// ## Safety
    /// Must keep returning a plain `Base?`, not `sending Base?` — see the
    /// note on `borrow()` above and fact 2 of the SAFETY note below.
    @inlinable
    package func restore() -> Base? {
        _storage.withLock { storage in
            storage.consumed ? nil : storage.base
        }
    }
}

// SAFETY: this conformance is sound only as the conjunction of three facts, none
// SAFETY: of them sufficient alone (see swift-primitives/swift-property-primitives#7
// SAFETY: for the probes that established this):
// SAFETY:
// SAFETY:   1. CONDITIONAL-CLAUSE STABILITY — the `where Base: Sendable` clause must
// SAFETY:      never widen or be dropped. `Mutex<Storage>` (`_UnsynchronizedBox<Storage>`
// SAFETY:      under Embedded) is unconditionally Sendable, but `borrow()` hands a copy
// SAFETY:      of `base` out of the lock — without this clause a non-Sendable `Base`
// SAFETY:      could cross isolation regions through that copy with zero compiler
// SAFETY:      signal. CHECKED: `Require.isSendable` in `Property.Consume.State
// SAFETY:      Tests.swift` asserts both directions — `State` is Sendable when `Base`
// SAFETY:      is, and is not when `Base` isn't — so widening this clause fails that
// SAFETY:      test instead of compiling silently.
// SAFETY:   2. NO `sending`-TYPED PUBLIC RETURN MENTIONING `Base` — `borrow()`,
// SAFETY:      `restore()`, and `consume()` must keep returning a plain `Base?`. Region
// SAFETY:      isolation re-merges a plain return with `self`'s region at the call
// SAFETY:      site; `sending Base?` would instead hand out a value disconnected from
// SAFETY:      `self` while `State` stays reachable from the original region — the
// SAFETY:      exact race this type exists to prevent. Adding `sending` to a return is
// SAFETY:      source-compatible, so nothing here compiles differently and no runtime
// SAFETY:      test observes it. NOT CHECKED LOCALLY: enforcement is a swift-linter
// SAFETY:      rule (swift-foundations/swift-institute-linter-rules#29), not this
// SAFETY:      package — see the per-member `## Safety` notes on the three accessors
// SAFETY:      above.
// SAFETY:   3. `Storage`'S SINGLE USE — its unconditional `@unchecked Sendable` must
// SAFETY:      stay internal and serve only as the payload of this `_storage` lock.
// SAFETY:      See the Safety Invariant on `Storage`, above.
// SAFETY:
// SAFETY: Do not drop or widen fact 1's constraint; do not add `sending` to a
// SAFETY: `Base`-typed return per fact 2; do not give `Storage` a second use per fact 3.
extension Property.Consume.State: @unchecked Sendable where Base: Sendable {}
