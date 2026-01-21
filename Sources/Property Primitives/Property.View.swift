extension Property where Base: ~Copyable {
    /// A borrowed view property for `~Copyable` types.
    ///
    /// `Property<Base, Tag>.View` provides borrowed access to a base value via pointer
    /// indirection. Extensions are added via constraints on the phantom `Tag` type.
    ///
    /// ## Property vs Property.View
    ///
    /// - **Property** — Owns the base value. Used via `_modify` + defer for CoW types.
    /// - **Property.View** — Borrows via pointer. Used via `_read` for `~Copyable` types.
    ///
    /// ## Usage
    ///
    /// Define a tag type and use `Property<Base, Tag>.View` as the accessor return type:
    ///
    /// ```swift
    /// extension Input.Access.Random where Self: ~Copyable {
    ///     public var access: Property<Self, Input.Access>.View {
    ///         mutating _read {
    ///             yield unsafe Property.View(&self)
    ///         }
    ///     }
    /// }
    ///
    /// extension Property<some Input.Access.Random & ~Copyable, Input.Access>.View {
    ///     public func element(at offset: Int) throws(Input.Access.Error) -> Base.Element {
    ///         // ...
    ///     }
    /// }
    /// ```
    @safe
    public struct View: ~Copyable, ~Escapable {
        @usableFromInline
        internal let _base: UnsafeMutablePointer<Base>

        /// Creates a view wrapping a pointer to the base value.
        ///
        /// - Parameter base: A pointer to the value to wrap.
        @inlinable
        @_lifetime(borrow base)
        public init(_ base: UnsafeMutablePointer<Base>) {
            unsafe _base = base
        }

        /// The pointer to the wrapped base value.
        @inlinable
        public var base: UnsafeMutablePointer<Base> {
            unsafe _base
        }
    }
}
