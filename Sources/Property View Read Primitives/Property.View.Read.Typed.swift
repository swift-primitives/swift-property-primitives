public import Property_Primitives_Core
public import Property_View_Primitives
public import Ownership_Borrow_Primitives
public import Tagged_Primitives

extension Property.View.Read where Base: ~Copyable {
    /// A read-only view on a `~Copyable` base with an `Element` parameter.
    ///
    /// `Property<Tag, Base>.View.Read.Typed<Element>` is the read-only
    /// counterpart of ``Property/View-swift.struct/Typed``. Access goes through
    /// `base.value`, which uses `Ownership.Borrow`'s `_read` accessor.
    ///
    /// Canonical usage — `~Copyable` container, read-only typed property extension:
    ///
    /// ```swift
    /// extension Container where Element: ~Copyable {
    ///     typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
    ///
    ///     enum Peek {}
    ///
    ///     var peek: Property<Peek>.View.Read.Typed<Element> {
    ///         _read {
    ///             yield Property<Peek>.View.Read.Typed(self)
    ///         }
    ///     }
    /// }
    ///
    /// extension Property_Primitives.Property.View.Read.Typed
    /// where Tag == Container<Element>.Peek, Base == Container<Element>,
    ///       Element: ~Copyable
    /// {
    ///     var count: Int { base.value.storage.count }
    /// }
    ///
    /// let size = container.peek.count
    /// ```
    ///
    /// Switch to ``Property/View-swift.struct/Typed`` when extensions need mutation.
    @safe
    public struct Typed<Element: ~Copyable>: ~Copyable, ~Escapable {
        @usableFromInline
        internal var _storage: Tagged<Tag, Ownership.Borrow<Base>>

        /// Creates a typed read-only view by borrowing the base value.
        ///
        /// - Parameter base: The value to borrow.
        @inlinable
        @_lifetime(borrow base)
        public init(_ base: borrowing Base) {
            self._storage = Tagged(__unchecked: (),
                                   Ownership.Borrow(borrowing: base))
        }
    }
}

extension Property.View.Read.Typed where Base: ~Copyable, Element: ~Copyable {
    /// The shared borrowed reference to the base value.
    @inlinable
    public var base: Ownership.Borrow<Base> {
        @_lifetime(borrow self)
        _read { yield _storage.rawValue }
    }
}
