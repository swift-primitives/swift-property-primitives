public import Ownership_Inout_Primitives
public import Property_Primitive
public import Tagged_Primitives

extension Property.Inout where Base: ~Copyable {
    // SAFETY: Transitive absorption of `Tagged`'s invariants;
    // SAFETY: this wrapper's API never re-exposes the underlying unsafety,
    // SAFETY: and lifetime / ownership constraints are inherited.
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

        // `@_transparent`, not `@inlinable`: at -O the caller keeps `[noescape]` on
        // its inout across the `mark_dependence [nonescaping]` result of a
        // non-transparent lifetime-dependent init and hoists loads of the same
        // storage; mandatory inlining keeps the address-take in the caller's frame.
        // See swift-primitives/swift-ownership-primitives#13.
        /// Creates a typed exclusive mutable accessor by borrowing the base value.
        ///
        /// - Parameter base: The value to borrow mutably.
        @_transparent
        @_lifetime(&base)
        public init(_ base: inout Base) {
            self._storage = Tagged(_unchecked: Ownership.Inout(mutating: &base))
        }
    }
}

extension Property.Inout.Typed where Base: ~Copyable, Element: ~Copyable {
    /// The exclusive mutable reference to the base value.
    @inlinable
    public var base: Ownership.Inout<Base> {
        @_lifetime(borrow self)
        _read { yield _storage.underlying }
    }
}
