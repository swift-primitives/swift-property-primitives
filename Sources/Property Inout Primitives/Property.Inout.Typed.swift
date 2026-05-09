public import Ownership_Inout_Primitives
public import Property_Primitives_Core
public import Tagged_Primitives

extension Property.Inout where Base: ~Copyable & ~Escapable {
    /// An exclusive mutable accessor on a `~Copyable` base with an `Element` parameter.
    ///
    /// `Property<Tag, Base>.Inout.Typed<Element>` is the `~Copyable` equivalent of
    /// `Property.Typed` (in `Property Typed Primitives`): it combines
    /// ``Property/Inout-swift.struct``'s mutable borrow access with an `Element`
    /// type parameter so `var` extensions can bind to it.
    ///
    /// Canonical usage — adopt the library type via a foundational typealias,
    /// pair the phantom tag with its accessor in its own extension, and declare
    /// the namespace's typed properties on `Property.Inout.Typed` at module scope:
    ///
    /// ```swift
    /// extension Container where Element: ~Copyable {
    ///     typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
    /// }
    ///
    /// extension Container where Element: ~Copyable {
    ///     enum Access {}
    ///
    ///     var access: Property<Access>.Inout.Typed<Element> {
    ///         mutating _read  { yield .init(&self) }
    ///         mutating _modify {
    ///             var accessor = Property<Access>.Inout.Typed<Element>(&self)
    ///             yield &accessor
    ///         }
    ///     }
    /// }
    ///
    /// extension Property.Inout.Typed
    /// where Tag == Container<Element>.Access, Base == Container<Element>,
    ///       Element: ~Copyable
    /// {
    ///     var count: Int { base.value.count }
    /// }
    /// ```
    ///
    /// For the `Copyable` equivalent, see `Property.Typed` (in
    /// `Property Typed Primitives`). For read-only access, see
    /// `Property.Borrow.Typed` (in `Property Borrow Primitives`).
    @safe
    public struct Typed<Element: ~Copyable>: ~Copyable, ~Escapable {
        @usableFromInline
        internal var _storage: Tagged<Tag, Ownership.Inout<Base>>
    }
}

extension Property.Inout.Typed where Base: ~Copyable, Element: ~Copyable {
    /// Creates a typed exclusive mutable accessor by borrowing the base value.
    ///
    /// - Parameter base: The value to borrow mutably.
    @inlinable
    @_lifetime(&base)
    public init(_ base: inout Base) {
        self._storage = Tagged(_unchecked: Ownership.Inout(mutating: &base))
    }
}

extension Property.Inout.Typed where Base: ~Copyable & ~Escapable, Element: ~Copyable {
    /// The exclusive mutable reference to the base value.
    @inlinable
    public var base: Ownership.Inout<Base> {
        @_lifetime(borrow self)
        _read { yield _storage.underlying }
    }
}

extension Property.Inout.Typed where Base: ~Copyable & ~Escapable, Element: ~Copyable {
    /// Unsafely creates a typed exclusive mutable accessor using a raw address,
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
