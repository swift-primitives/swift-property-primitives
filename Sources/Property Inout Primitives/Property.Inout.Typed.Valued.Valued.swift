public import Ownership_Inout_Primitives
public import Property_Primitives_Core
public import Tagged_Primitives

extension Property.Inout.Typed.Valued where Base: ~Copyable & ~Escapable, Element: ~Copyable {
    /// A ``Property/Inout-swift.struct/Typed/Valued`` with a second value-generic.
    ///
    /// `Property<Tag, Base>.Inout.Typed<Element>.Valued<n>.Valued<m>` lifts two
    /// compile-time integers to the type level so extension where-clauses can
    /// bind both alongside `Element` and `Base`. Required when containers have
    /// two value generics, e.g. `Buffer<Element>.Linked<N>.Inline<capacity>`.
    ///
    /// Canonical usage — two value generics in scope:
    ///
    /// ```swift
    /// extension Buffer.Linked.Inline where Element: ~Copyable {
    ///     var insert: Property<Buffer<Element>.Linked<N>.Insert, Self>
    ///         .Inout.Typed<Element>.Valued<N>.Valued<capacity>
    ///     {
    ///         mutating _read  { yield .init(&self) }
    ///         mutating _modify {
    ///             var accessor: Property<Buffer<Element>.Linked<N>.Insert, Self>
    ///                 .Inout.Typed<Element>.Valued<N>.Valued<capacity> = .init(&self)
    ///             yield &accessor
    ///         }
    ///     }
    /// }
    ///
    /// extension Property.Inout.Typed.Valued.Valued
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
    }
}

extension Property.Inout.Typed.Valued.Valued where Base: ~Copyable, Element: ~Copyable {
    /// Creates a valued exclusive mutable accessor by borrowing the base value.
    ///
    /// - Parameter base: The value to borrow mutably.
    @inlinable
    @_lifetime(&base)
    public init(_ base: inout Base) {
        self._storage = Tagged(_unchecked: Ownership.Inout(mutating: &base))
    }
}

extension Property.Inout.Typed.Valued.Valued where Base: ~Copyable & ~Escapable, Element: ~Copyable {
    /// The exclusive mutable reference to the base value.
    @inlinable
    public var base: Ownership.Inout<Base> {
        @_lifetime(borrow self)
        _read { yield _storage.underlying }
    }
}

extension Property.Inout.Typed.Valued.Valued where Base: ~Copyable & ~Escapable, Element: ~Copyable {
    /// Unsafely creates a valued exclusive mutable accessor using a raw address,
    /// with lifetime based on the mutating owner.
    ///
    /// This is the only construction path available when `Base` is `~Escapable`.
    /// Mirrors ``Property/Inout-swift.struct/init(unsafeRawAddress:mutating:)``.
    ///
    /// - Parameters:
    ///   - pointer: The raw address of the value to mutate.
    ///   - owner: The owning instance whose mutation scope bounds this
    ///     reference.
    @unsafe
    @inlinable
    @_lifetime(&owner)
    public init<Owner: ~Copyable & ~Escapable>(
        unsafeRawAddress pointer: UnsafeMutableRawPointer,
        mutating owner: inout Owner
    ) {
        self._storage = Tagged(_unchecked: unsafe Ownership.Inout(unsafeRawAddress: pointer, mutating: &owner))
    }
}
