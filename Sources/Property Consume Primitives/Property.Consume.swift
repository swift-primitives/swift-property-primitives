public import Property_Primitive

extension Property where Base: Copyable {
    /// A property that supports both borrowing and consuming access.
    ///
    /// `Property<Tag, Base>.Consume<Element>` enables call sites like
    /// `container.forEach.consuming { }` where the container is optionally emptied by
    /// which method the caller invokes.
    ///
    /// Requires `Base: Copyable`. For `~Copyable` containers use
    /// `Property.Inout` (in `Property Inout Primitives`) with the `.consuming()`
    /// namespace-method pattern.
    ///
    /// Canonical usage — adopt the library type via a foundational typealias,
    /// pair the phantom tag with its accessor in its own extension, and declare
    /// the namespace's methods on `Property.Consume` at module scope:
    ///
    /// ```swift
    /// extension Container {
    ///     typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
    /// }
    ///
    /// extension Container {
    ///     enum ForEach {}
    ///
    ///     var forEach: Property<ForEach>.Consume<Element> {
    ///         _read { yield Property<ForEach>.Consume(self) }
    ///         mutating _modify {
    ///             var property = Property<ForEach>.Consume(self)
    ///             self = Container()
    ///             defer {
    ///                 if let restored = property.restore() {
    ///                     self = restored
    ///                 }
    ///             }
    ///             yield &property
    ///         }
    ///     }
    /// }
    ///
    /// extension Property.Consume
    /// where Tag == Container<Element>.ForEach, Base == Container<Element> {
    ///     func callAsFunction(_ body: (Element) -> Void) {
    ///         guard let base = borrow() else { return }
    ///         for element in base.elements { body(element) }
    ///     }
    ///
    ///     mutating func consuming(_ body: (Element) -> Void) {
    ///         guard let base = consume() else { return }
    ///         for element in base.elements { body(element) }
    ///     }
    /// }
    ///
    /// container.forEach { print($0) }             // borrow — container preserved
    /// container.forEach.consuming { process($0) } // consume — container emptied
    /// ```
    ///
    /// For the state-tracking mechanism, the `restore()` contract, and worked
    /// examples, see the Property.Consume article in the `Property Consume
    /// Primitives` DocC catalog.
    public struct Consume<Element>: ~Copyable {
        @usableFromInline
        internal let _state: State

        /// Creates a consume accessor wrapping the given base value.
        ///
        /// ## Ownership
        /// The parameter is `consuming` but deliberately **not** `sending`. The
        /// canonical usage above builds the accessor from `self` inside a
        /// property accessor, where `self` is task-isolated and therefore never
        /// a disconnected value; requiring `sending` would make the documented
        /// pattern uncompilable for every non-Sendable `Base`. Nothing crosses
        /// an isolation boundary at this call site: `Consume` — and the `State`
        /// it allocates — is `Sendable` only when `Base` is, so for a
        /// non-Sendable `Base` the accessor stays in the caller's region.
        ///
        /// - Parameter base: The value to wrap. Ownership is transferred to the state.
        @inlinable
        public init(_ base: consuming Base) {
            self._state = State(base)
        }

        /// Creates a consume accessor sharing an existing state.
        ///
        /// - Parameter state: The state object to use.
        @inlinable
        public init(state: State) {
            self._state = state
        }
    }
}

// MARK: - Projections

extension Property.Consume {
    /// The underlying state object.
    @inlinable
    public var state: State { _state }

    /// Whether the base has been consumed.
    @inlinable
    public var isConsumed: Bool { _state.isConsumed }
}

// MARK: - Borrowing Access

extension Property.Consume {
    /// Borrows the base value for read-only access.
    ///
    /// Returns `nil` if already consumed.
    ///
    /// - Returns: The base value, or `nil` if consumed.
    @inlinable
    public func borrow() -> Base? {
        _state.borrow()
    }
}

// MARK: - Consuming Access

extension Property.Consume {
    /// Consumes the base value, marking it as consumed.
    ///
    /// After calling this method:
    /// - `isConsumed` returns `true`
    /// - `borrow()` returns `nil`
    /// - `restore()` returns `nil`
    ///
    /// Returns `nil` if already consumed.
    ///
    /// The check, the consumed-flag set, and the base clear happen atomically
    /// under `State`'s internal lock (see `Property.Consume.State`'s Safety
    /// Invariant), so this is race-safe when this `Consume`'s `State` is
    /// shared with another `Consume` instance via `init(state:)`.
    ///
    /// - Returns: The base value, or `nil` if already consumed.
    @inlinable
    public mutating func consume() -> Base? {
        _state.consume()
    }
}

// MARK: - Restoration

extension Property.Consume {
    /// Returns the base value if the consuming path was not taken, `nil` if consumed.
    ///
    /// Call this in the `defer` block of your accessor to decide whether to restore
    /// the container on scope exit:
    ///
    /// ```swift
    /// defer {
    ///     if let restored = property.restore() {
    ///         self = restored
    ///     }
    /// }
    /// ```
    ///
    /// - Returns: The base value if the consuming path was not taken, `nil` if consumed.
    @inlinable
    public func restore() -> Base? {
        _state.restore()
    }
}

// MARK: - Conditional Conformances

extension Property.Consume: Sendable where Base: Sendable {}
