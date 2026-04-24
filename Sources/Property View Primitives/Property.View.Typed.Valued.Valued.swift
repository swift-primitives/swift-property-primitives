public import Property_Primitives_Core

extension Property.View.Typed.Valued where Base: ~Copyable, Element: ~Copyable {
    /// A ``Property/View-swift.struct/Typed/Valued`` with a second value-generic.
    ///
    /// `Property<Tag, Base>.View.Typed<Element>.Valued<n>.Valued<m>` lifts two
    /// compile-time integers to the type level so extension where-clauses can bind
    /// both alongside `Element` and `Base`. Required when containers have two value
    /// generics, e.g. `Buffer<Element>.Linked<N>.Inline<capacity>`.
    ///
    /// Canonical usage — two value generics in scope:
    ///
    /// ```swift
    /// extension Buffer.Linked.Inline where Element: ~Copyable {
    ///     var insert: Property<Buffer<Element>.Linked<N>.Insert, Self>
    ///         .View.Typed<Element>.Valued<N>.Valued<capacity>
    ///     {
    ///         mutating _read  { yield unsafe .init(&self) }
    ///         mutating _modify {
    ///             var view: Property<Buffer<Element>.Linked<N>.Insert, Self>
    ///                 .View.Typed<Element>.Valued<N>.Valued<capacity> = unsafe .init(&self)
    ///             yield &view
    ///         }
    ///     }
    /// }
    ///
    /// extension Property.View.Typed.Valued.Valued
    /// where Tag == Buffer<Element>.Linked<n>.Insert,
    ///       Base == Buffer<Element>.Linked<n>.Inline<m>,
    ///       Element: ~Copyable {
    ///     mutating func front(_ element: consuming Element) throws(Error) { }
    /// }
    /// ```
    ///
    /// For value-generic verbosity trade-offs and the recommended tag-enum-`View`
    /// typealias pattern that shortens call sites, see the
    /// Property.View.Typed.Valued.Valued article in the `Property View Primitives`
    /// DocC catalog.
    @safe
    public struct Valued<let m: Int>: ~Copyable, ~Escapable {
        @usableFromInline
        internal let _base: UnsafeMutablePointer<Base>

        /// Creates a valued view wrapping a pointer to the base value.
        ///
        /// - Parameter base: A pointer to the value to wrap.
        @inlinable
        @_lifetime(borrow base)
        public init(_ base: UnsafeMutablePointer<Base>) {
            unsafe _base = base
        }
    }
}

extension Property.View.Typed.Valued.Valued where Base: ~Copyable, Element: ~Copyable {
    @inlinable
    public var base: UnsafeMutablePointer<Base> {
        unsafe _base
    }
}
