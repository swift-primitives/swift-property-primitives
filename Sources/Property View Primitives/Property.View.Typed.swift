public import Property_Primitives_Core
public import Ownership_Inout_Primitives
public import Tagged_Primitives

extension Property.View where Base: ~Copyable {
    /// A mutable view on a `~Copyable` base with an `Element` parameter.
    ///
    /// `Property<Tag, Base>.View.Typed<Element>` is the `~Copyable` equivalent of
    /// `Property.Typed` (in `Property Typed Primitives`): it combines
    /// ``Property/View-swift.struct``'s mutable borrow access with an `Element`
    /// type parameter so `var` extensions can bind to it.
    ///
    /// Canonical usage — adopt the library type via a foundational typealias,
    /// pair the phantom tag with its accessor in its own extension, and declare
    /// the namespace's typed properties on `Property.View.Typed` at module scope:
    ///
    /// ```swift
    /// extension Container where Element: ~Copyable {
    ///     typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
    /// }
    ///
    /// extension Container where Element: ~Copyable {
    ///     enum Access {}
    ///
    ///     var access: Property<Access>.View.Typed<Element> {
    ///         mutating _read  { yield .init(&self) }
    ///         mutating _modify {
    ///             var view = Property<Access>.View.Typed<Element>(&self)
    ///             yield &view
    ///         }
    ///     }
    /// }
    ///
    /// extension Property.View.Typed
    /// where Tag == Container<Element>.Access, Base == Container<Element>,
    ///       Element: ~Copyable
    /// {
    ///     var count: Int { base.value.count }
    /// }
    /// ```
    ///
    /// For the `Copyable` equivalent, see `Property.Typed` (in
    /// `Property Typed Primitives`). For read-only access, see
    /// `Property.View.Read.Typed` (in `Property View Read Primitives`).
    @safe
    public struct Typed<Element: ~Copyable>: ~Copyable, ~Escapable {
        @usableFromInline
        internal var _storage: Tagged<Tag, Ownership.Inout<Base>>

        /// Creates a typed view by borrowing the base value exclusively.
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

extension Property.View.Typed where Base: ~Copyable, Element: ~Copyable {
    /// The exclusive mutable reference to the base value.
    @inlinable
    public var base: Ownership.Inout<Base> {
        @_lifetime(borrow self)
        _read { yield _storage.rawValue }
    }
}
