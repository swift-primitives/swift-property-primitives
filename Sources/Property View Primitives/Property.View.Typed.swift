public import Property_Primitives_Core

extension Property.View where Base: ~Copyable {
    /// A mutable view on a `~Copyable` base with an `Element` parameter.
    ///
    /// `Property<Tag, Base>.View.Typed<Element>` is the `~Copyable` equivalent of
    /// `Property.Typed` (in `Property Typed Primitives`): it combines
    /// ``Property/View-swift.struct``'s pointer access with an `Element` type
    /// parameter so `var` extensions can bind to it.
    ///
    /// Canonical usage — `~Copyable` container, typed property extension:
    ///
    /// ```swift
    /// extension Container where Element: ~Copyable {
    ///     typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
    ///
    ///     enum Access {}
    ///
    ///     var access: Property<Access>.View.Typed<Element> {
    ///         mutating _read {
    ///             yield unsafe Property<Access>.View.Typed(&self)
    ///         }
    ///         mutating _modify {
    ///             var view = unsafe Property<Access>.View.Typed<Element>(&self)
    ///             yield &view
    ///         }
    ///     }
    /// }
    ///
    /// extension Property_Primitives.Property.View.Typed
    /// where Tag == Container<Element>.Access, Base == Container<Element>,
    ///       Element: ~Copyable
    /// {
    ///     var count: Int { unsafe base.pointee.count }
    /// }
    /// ```
    ///
    /// For the `Copyable` equivalent, see `Property.Typed` (in
    /// `Property Typed Primitives`). For read-only access, see
    /// `Property.View.Read.Typed` (in `Property View Read Primitives`).
    @safe
    public struct Typed<Element: ~Copyable>: ~Copyable, ~Escapable {
        @usableFromInline
        internal let _base: UnsafeMutablePointer<Base>

        /// Creates a typed view wrapping a pointer to the base value.
        ///
        /// - Parameter base: A pointer to the value to wrap.
        @inlinable
        @_lifetime(borrow base)
        public init(_ base: UnsafeMutablePointer<Base>) {
            unsafe _base = base
        }
    }
}

extension Property.View.Typed where Base: ~Copyable, Element: ~Copyable {
    @inlinable
    public var base: UnsafeMutablePointer<Base> {
        unsafe _base
    }
}
