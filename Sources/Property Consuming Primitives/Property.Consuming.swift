public import Property_Primitives_Core

extension Property where Base: Copyable {
    /// A property that supports both borrowing and consuming access.
    ///
    /// `Property<Tag, Base>.Consuming<Element>` enables call sites like
    /// `container.forEach.consuming { }` where the container is optionally emptied by
    /// which method the caller invokes.
    ///
    /// Requires `Base: Copyable`. For `~Copyable` containers use
    /// `Property.View` (in `Property View Primitives`) with the `.consuming()`
    /// namespace-method pattern.
    ///
    /// Canonical usage — adopt the library type via a foundational typealias,
    /// pair the phantom tag with its accessor in its own extension, and declare
    /// the namespace's methods on `Property.Consuming` at module scope:
    ///
    /// ```swift
    /// extension Container {
    ///     typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
    /// }
    ///
    /// extension Container {
    ///     enum ForEach {}
    ///
    ///     var forEach: Property<ForEach>.Consuming<Element> {
    ///         _read { yield Property<ForEach>.Consuming(self) }
    ///         mutating _modify {
    ///             var property = Property<ForEach>.Consuming(self)
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
    /// extension Property.Consuming
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
    /// examples, see the Property.Consuming article in the `Property Consuming
    /// Primitives` DocC catalog.
    public struct Consuming<Element>: ~Copyable {
        @usableFromInline
        internal let _state: State

        /// Creates a consuming property wrapping the given base value.
        ///
        /// - Parameter base: The value to wrap. Ownership is transferred to the state.
        @inlinable
        public init(_ base: consuming Base) {
            self._state = State(base)
        }

        /// Creates a consuming property sharing an existing state.
        ///
        /// - Parameter state: The state object to use.
        @inlinable
        public init(state: State) {
            self._state = state
        }
    }
}

// MARK: - Projections

extension Property.Consuming {
    /// The underlying state object.
    @inlinable
    public var state: State { _state }

    /// Whether the base has been consumed.
    @inlinable
    public var isConsumed: Bool { _state._consumed }
}

// MARK: - Borrowing Access

extension Property.Consuming {
    /// Borrows the base value for read-only access.
    ///
    /// Returns `nil` if already consumed.
    ///
    /// - Returns: The base value, or `nil` if consumed.
    @inlinable
    public func borrow() -> Base? {
        _state._base
    }
}

// MARK: - Consuming Access

extension Property.Consuming {
    /// Consumes the base value, marking it as consumed.
    ///
    /// After calling this method:
    /// - `isConsumed` returns `true`
    /// - `borrow()` returns `nil`
    /// - `restore()` returns `nil`
    ///
    /// Returns `nil` if already consumed.
    ///
    /// - Returns: The base value, or `nil` if already consumed.
    @inlinable
    public mutating func consume() -> Base? {
        guard let base = _state._base else { return nil }
        _state._consumed = true
        _state._base = nil
        return base
    }
}

// MARK: - Restoration

extension Property.Consuming {
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
        guard !_state._consumed else { return nil }
        return _state._base
    }
}

// MARK: - Conditional Conformances

extension Property.Consuming: Sendable where Base: Sendable {}
