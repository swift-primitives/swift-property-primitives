public import Ownership_Borrow_Primitives
public import Property_Primitives_Core
public import Tagged_Primitives

extension Property.Borrow.Typed where Base: ~Copyable, Element: ~Copyable {
    /// A ``Property/Borrow/Typed`` with a value-generic parameter.
    ///
    /// `Property<Tag, Base>.Borrow.Typed<Element>.Valued<n>` is the read-only
    /// counterpart of ``Property/Inout-swift.struct/Typed/Valued`` — it lifts
    /// one compile-time integer (e.g. `N`) to the type level so extension
    /// where-clauses can bind it alongside `Element` and `Base`.
    ///
    /// Canonical usage — adopt the library type via a foundational typealias,
    /// pair the phantom tag with its accessor in its own extension, and declare
    /// the namespace's methods on `Property.Borrow.Typed.Valued` at module
    /// scope:
    ///
    /// ```swift
    /// extension List.Linked where Element: ~Copyable {
    ///     typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
    /// }
    ///
    /// extension List.Linked where Element: ~Copyable {
    ///     enum Peek {}
    ///
    ///     var peek: Property<Peek>.Borrow.Typed<Element>.Valued<N> {
    ///         _read {
    ///             yield Property<Peek>.Borrow.Typed<Element>.Valued<N>(self)
    ///         }
    ///     }
    /// }
    ///
    /// extension Property.Borrow.Typed.Valued
    /// where Tag == List<Element>.Linked<n>.Peek, Base == List<Element>.Linked<n>,
    ///       Element: ~Copyable {
    ///     func first<R>(_ body: (borrowing Element) -> R) -> R? {
    ///         // Element and n are in scope.
    ///     }
    /// }
    /// ```
    ///
    /// Switch to ``Property/Inout-swift.struct/Typed/Valued`` when mutation is needed.
    @safe
    public struct Valued<let n: Int>: ~Copyable, ~Escapable {
        @usableFromInline
        internal var _storage: Tagged<Tag, Ownership.Borrow<Base>>

        /// Creates a valued read-only accessor by borrowing the base value.
        ///
        /// - Parameter base: The value to borrow.
        @inlinable
        @_lifetime(borrow base)
        public init(_ base: borrowing Base) {
            self._storage = Tagged(_unchecked: Ownership.Borrow(borrowing: base))
        }
    }
}

extension Property.Borrow.Typed.Valued where Base: ~Copyable, Element: ~Copyable {
    /// The shared borrowed reference to the base value.
    @inlinable
    public var base: Ownership.Borrow<Base> {
        @_lifetime(borrow self)
        _read { yield _storage.underlying }
    }
}
