public import Ownership_Borrow_Primitives
public import Property_Primitives_Core
public import Tagged_Primitives

extension Property.Borrow where Base: ~Copyable & ~Escapable {
    /// A read-only accessor on a `~Copyable` base with an `Element` parameter.
    ///
    /// `Property<Tag, Base>.Borrow.Typed<Element>` is the read-only
    /// counterpart of ``Property/Inout-swift.struct/Typed``. Access goes through
    /// `base.value`, which uses `Ownership.Borrow`'s `_read` accessor.
    ///
    /// Canonical usage — adopt the library type via a foundational typealias,
    /// pair the phantom tag with its accessor in its own extension, and declare
    /// the namespace's typed properties on `Property.Borrow.Typed` at module
    /// scope:
    ///
    /// ```swift
    /// extension Container where Element: ~Copyable {
    ///     typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
    /// }
    ///
    /// extension Container where Element: ~Copyable {
    ///     enum Peek {}
    ///
    ///     var peek: Property<Peek>.Borrow.Typed<Element> {
    ///         _read {
    ///             yield Property<Peek>.Borrow.Typed(self)
    ///         }
    ///     }
    /// }
    ///
    /// extension Property.Borrow.Typed
    /// where Tag == Container<Element>.Peek, Base == Container<Element>,
    ///       Element: ~Copyable
    /// {
    ///     var count: Int { base.value.storage.count }
    /// }
    ///
    /// let size = container.peek.count
    /// ```
    ///
    /// Switch to ``Property/Inout-swift.struct/Typed`` when extensions need mutation.
    @safe
    public struct Typed<Element: ~Copyable>: ~Copyable, ~Escapable {
        @usableFromInline
        internal var _storage: Tagged<Tag, Ownership.Borrow<Base>>
    }
}

extension Property.Borrow.Typed where Base: ~Copyable, Element: ~Copyable {
    /// Creates a typed read-only accessor by borrowing the base value.
    ///
    /// - Parameter base: The value to borrow.
    @inlinable
    @_lifetime(borrow base)
    public init(_ base: borrowing Base) {
        self._storage = Tagged(_unchecked: Ownership.Borrow(borrowing: base))
    }
}

extension Property.Borrow.Typed where Base: ~Copyable & ~Escapable, Element: ~Copyable {
    /// The shared borrowed reference to the base value.
    @inlinable
    public var base: Ownership.Borrow<Base> {
        @_lifetime(borrow self)
        _read { yield _storage.underlying }
    }
}

extension Property.Borrow.Typed where Base: ~Copyable & ~Escapable, Element: ~Copyable {
    /// Unsafely creates a typed read-only accessor using a raw address, with
    /// lifetime based on the borrowed owner.
    ///
    /// This is the only construction path available when `Base` is `~Escapable`.
    /// Mirrors ``Property/Borrow/init(unsafeRawAddress:borrowing:)``.
    ///
    /// - Parameters:
    ///   - pointer: The raw address of the value to borrow.
    ///   - owner: The owning instance whose lifetime scopes this borrow.
    @unsafe
    @inlinable
    @_lifetime(borrow owner)
    public init<Owner: ~Copyable & ~Escapable>(
        unsafeRawAddress pointer: UnsafeRawPointer,
        borrowing owner: borrowing Owner
    ) {
        self._storage = Tagged(_unchecked: unsafe Ownership.Borrow(unsafeRawAddress: pointer, borrowing: owner))
    }
}
