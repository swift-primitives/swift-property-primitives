public import Ownership_Inout_Primitives
public import Property_Primitive
public import Tagged_Primitives

extension Property.Inout.Typed.Valued where Base: ~Copyable, Element: ~Copyable {
    // SAFETY: Transitive absorption of `Tagged`'s invariants;
    // SAFETY: this wrapper's API never re-exposes the underlying unsafety,
    // SAFETY: and lifetime / ownership constraints are inherited.
    /// A ``Property/Inout-swift.struct/Typed/Valued`` with a second value-generic.
    ///
    /// `Property<Tag, Base>.Inout.Typed<Element>.Valued<n>.Valued<m>` lifts two
    /// compile-time integers to the type level so extension where-clauses can
    /// bind both alongside `Element` and `Base`. Required when containers have
    /// two value generics, e.g. `Buffer<Storage<Element>.Contiguous<Memory.Heap<Element>>>.Linked<N>.Inline<capacity>`.
    ///
    /// Canonical usage — two value generics in scope:
    ///
    /// ```swift
    /// extension Buffer.Linked.Inline where Element: ~Copyable {
    ///     var insert: Property<Buffer<Storage<Element>.Contiguous<Memory.Heap<Element>>>.Linked<N>.Insert, Self>
    ///         .Inout.Typed<Element>.Valued<N>.Valued<capacity>
    ///     {
    ///         mutating _read  { yield .init(&self) }
    ///         mutating _modify {
    ///             var accessor: Property<Buffer<Storage<Element>.Contiguous<Memory.Heap<Element>>>.Linked<N>.Insert, Self>
    ///                 .Inout.Typed<Element>.Valued<N>.Valued<capacity> = .init(&self)
    ///             yield &accessor
    ///         }
    ///     }
    /// }
    ///
    /// extension Property.Inout.Typed.Valued.Valued
    /// where Tag == Buffer<Storage<Element>.Contiguous<Memory.Heap<Element>>>.Linked<n>.Insert,
    ///       Base == Buffer<Storage<Element>.Contiguous<Memory.Heap<Element>>>.Linked<n>.Inline<m>,
    ///       Element: ~Copyable {
    ///     mutating func front(_ element: consuming Element) throws(Error) { }
    /// }
    /// ```
    @safe
    public struct Valued<let m: Int>: ~Copyable, ~Escapable {
        @usableFromInline
        internal var _storage: Tagged<Tag, Ownership.Inout<Base>>

        /// Creates a valued exclusive mutable accessor by borrowing the base value.
        ///
        /// - Parameter base: The value to borrow mutably.
        // `@_transparent`, not `@inlinable`: at -O the caller keeps `[noescape]` on
        // its inout across the `mark_dependence [nonescaping]` result of a
        // non-transparent lifetime-dependent init and hoists loads of the same
        // storage; mandatory inlining keeps the address-take in the caller's frame.
        // See swift-primitives/swift-ownership-primitives#13.
        @_transparent
        @_lifetime(&base)
        public init(_ base: inout Base) {
            self._storage = Tagged(_unchecked: Ownership.Inout(mutating: &base))
        }
    }
}

extension Property.Inout.Typed.Valued.Valued where Base: ~Copyable, Element: ~Copyable {
    /// The exclusive mutable reference to the base value.
    @inlinable
    public var base: Ownership.Inout<Base> {
        @_lifetime(borrow self)
        _read { yield _storage.underlying }
    }
}
