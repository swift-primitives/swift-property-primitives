public import Property_Primitives_Core
public import Ownership_Inout_Primitives
public import Tagged_Primitives

extension Property.View.Typed.Valued where Base: ~Copyable, Element: ~Copyable {
    /// A ``Property/View-swift.struct/Typed/Valued`` with a second value-generic.
    ///
    /// `Property<Tag, Base>.View.Typed<Element>.Valued<n>.Valued<m>` lifts two
    /// compile-time integers to the type level so extension where-clauses can
    /// bind both alongside `Element` and `Base`. Required when containers have
    /// two value generics, e.g. `Buffer<Element>.Linked<N>.Inline<capacity>`.
    ///
    /// Canonical usage — two value generics in scope:
    ///
    /// ```swift
    /// extension Buffer.Linked.Inline where Element: ~Copyable {
    ///     var insert: Property<Buffer<Element>.Linked<N>.Insert, Self>
    ///         .View.Typed<Element>.Valued<N>.Valued<capacity>
    ///     {
    ///         mutating _read  { yield .init(&self) }
    ///         mutating _modify {
    ///             var view: Property<Buffer<Element>.Linked<N>.Insert, Self>
    ///                 .View.Typed<Element>.Valued<N>.Valued<capacity> = .init(&self)
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
    @safe
    public struct Valued<let m: Int>: ~Copyable, ~Escapable {
        @usableFromInline
        internal var _storage: Tagged<Tag, Ownership.Inout<Base>>

        /// Creates a valued view by borrowing the base value exclusively.
        ///
        /// - Parameter base: The value to borrow mutably.
        @inlinable
        @_lifetime(&base)
        public init(_ base: inout Base) {
            self._storage = Tagged(__unchecked: (),
                                   Ownership.Inout(mutating: &base))
        }
    }
}

extension Property.View.Typed.Valued.Valued where Base: ~Copyable, Element: ~Copyable {
    /// The exclusive mutable reference to the base value.
    @inlinable
    public var base: Ownership.Inout<Base> {
        @_lifetime(borrow self)
        _read { yield _storage.rawValue }
    }
}
