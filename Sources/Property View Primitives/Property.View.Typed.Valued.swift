public import Property_Primitives_Core
public import Ownership_Inout_Primitives
public import Tagged_Primitives

extension Property.View.Typed where Base: ~Copyable, Element: ~Copyable {
    /// A ``Property/View-swift.struct/Typed`` with one value-generic parameter.
    ///
    /// `Property<Tag, Base>.View.Typed<Element>.Valued<n>` lifts a compile-time
    /// integer (e.g. `capacity`, `N`) to the type level so extension where-
    /// clauses can bind it alongside `Element` and `Base`.
    ///
    /// Canonical usage — adopt the library type via a foundational typealias,
    /// declare the accessor on the container, and declare the namespace's
    /// methods on `Property.View.Typed.Valued` at module scope:
    ///
    /// ```swift
    /// extension Array.Inline where Element: ~Copyable {
    ///     typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
    /// }
    ///
    /// extension Array.Inline where Element: ~Copyable {
    ///     var forEach: Property<Sequence.ForEach>.View.Typed<Element>.Valued<capacity> {
    ///         mutating _read  { yield .init(&self) }
    ///         mutating _modify {
    ///             var view: Property<Sequence.ForEach>.View.Typed<Element>.Valued<capacity> = .init(&self)
    ///             yield &view
    ///         }
    ///     }
    /// }
    ///
    /// extension Property.View.Typed.Valued
    /// where Tag == Sequence.ForEach, Base == Array<Element>.Inline<n>,
    ///       Element: ~Copyable {
    ///     func callAsFunction(_ body: (borrowing Element) -> Void) {
    ///         // Both Element and n are in scope.
    ///     }
    /// }
    /// ```
    ///
    /// For two value generics, see ``Property/View-swift.struct/Typed/Valued/Valued``.
    @safe
    public struct Valued<let n: Int>: ~Copyable, ~Escapable {
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

extension Property.View.Typed.Valued where Base: ~Copyable, Element: ~Copyable {
    /// The exclusive mutable reference to the base value.
    @inlinable
    public var base: Ownership.Inout<Base> {
        @_lifetime(borrow self)
        _read { yield _storage.rawValue }
    }
}
