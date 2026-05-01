public import Property_Primitives_Core
public import Property_View_Primitives
@_exported public import Ownership_Borrow_Primitives
public import Tagged_Primitives

extension Property.View where Base: ~Copyable {
    /// A read-only view on a `~Copyable` base.
    ///
    /// `Property<Tag, Base>.View.Read` is a thin wrapper over
    /// `Tagged<Tag, Ownership.Borrow<Base>>` — the phantom-tagged shared
    /// immutable reference composition from `Tagged_Primitives` and
    /// `Ownership_Primitives`. Access goes through `base.value`, which uses
    /// `Ownership.Borrow`'s `_read` accessor.
    ///
    /// Canonical usage — adopt the library type via a foundational typealias,
    /// pair the phantom tag with its accessor in its own extension, and declare
    /// the namespace's properties on `Property.View.Read` at module scope:
    ///
    /// ```swift
    /// extension Container where Self: ~Copyable {
    ///     typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
    /// }
    ///
    /// extension Container where Self: ~Copyable {
    ///     enum Inspect {}
    ///
    ///     var inspect: Property<Inspect>.View.Read {
    ///         _read {
    ///             yield Property<Inspect>.View.Read(self)
    ///         }
    ///     }
    /// }
    ///
    /// extension Property.View.Read
    /// where Tag == Container.Inspect, Base == Container {
    ///     var count: Int { base.value.count }
    /// }
    ///
    /// let size = container.inspect.count
    /// ```
    ///
    /// Use this variant for read-only namespaces; switch to
    /// ``Property/View-swift.struct`` when extensions need to mutate or consume.
    @safe
    public struct Read: ~Copyable, ~Escapable {
        @usableFromInline
        internal var _storage: Tagged<Tag, Ownership.Borrow<Base>>

        /// Creates a read-only view by borrowing the base value.
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

extension Property.View.Read where Base: ~Copyable {
    /// The shared borrowed reference to the base value.
    ///
    /// Use `base.value` to read the underlying value.
    @inlinable
    public var base: Ownership.Borrow<Base> {
        @_lifetime(borrow self)
        _read { yield _storage.rawValue }
    }
}
