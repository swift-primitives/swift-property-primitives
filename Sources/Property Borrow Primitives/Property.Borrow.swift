@_exported public import Ownership_Borrow_Primitives
public import Property_Primitives_Core
public import Tagged_Primitives

extension Property where Base: ~Copyable & ~Escapable {
    /// A read-only accessor on a `~Copyable` base.
    ///
    /// `Property<Tag, Base>.Borrow` is a thin wrapper over
    /// `Tagged<Tag, Ownership.Borrow<Base>>` — the phantom-tagged shared
    /// immutable reference composition from `Tagged_Primitives` and
    /// `Ownership_Primitives`. Access goes through `base.value`, which uses
    /// `Ownership.Borrow`'s `_read` accessor.
    ///
    /// > Important: `Property.Borrow` is NOT a typed view over a specific
    /// > byte buffer like `String.Borrowed` (in `swift-string-primitives`)
    /// > or `Path.Borrowed` (in `swift-path-primitives`). Those are concrete
    /// > `~Escapable` view types over a null-terminated UTF-8 byte
    /// > sequence, each with its own scanning, decomposition, and
    /// > projection API. `Property.Borrow` is generic over an arbitrary
    /// > `~Copyable` base type and serves only as an extension-namespace
    /// > dispatch wrapper — its API surface is empty until consumers
    /// > extend it. Roughly: `Property.Borrow<Tag, T>` is to extensions
    /// > what `Tagged<Tag, T>` is to identity, while `String.Borrowed` /
    /// > `Path.Borrowed` are concrete data structures sharing the
    /// > "borrowed" name only by analogy with the borrow-only access mode.
    ///
    /// Canonical usage — adopt the library type via a foundational typealias,
    /// pair the phantom tag with its accessor in its own extension, and declare
    /// the namespace's properties on `Property.Borrow` at module scope:
    ///
    /// ```swift
    /// extension Container where Self: ~Copyable {
    ///     typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
    /// }
    ///
    /// extension Container where Self: ~Copyable {
    ///     enum Inspect {}
    ///
    ///     var inspect: Property<Inspect>.Borrow {
    ///         _read {
    ///             yield Property<Inspect>.Borrow(self)
    ///         }
    ///     }
    /// }
    ///
    /// extension Property.Borrow
    /// where Tag == Container.Inspect, Base == Container {
    ///     var count: Int { base.value.count }
    /// }
    ///
    /// let size = container.inspect.count
    /// ```
    ///
    /// Use this variant for read-only namespaces; switch to
    /// ``Property/Inout-swift.struct`` when extensions need to mutate or consume.
    @safe
    public struct Borrow: ~Copyable, ~Escapable {
        @usableFromInline
        internal var _storage: Tagged<Tag, Ownership.Borrow<Base>>
    }
}

extension Property.Borrow where Base: ~Copyable {
    /// Creates a read-only accessor by borrowing the base value.
    ///
    /// - Parameter base: The value to borrow.
    @inlinable
    @_lifetime(borrow base)
    public init(_ base: borrowing Base) {
        self._storage = Tagged(_unchecked: Ownership.Borrow(borrowing: base))
    }
}

extension Property.Borrow where Base: ~Copyable & ~Escapable {
    /// The shared borrowed reference to the base value.
    ///
    /// Use `base.value` to read the underlying value.
    @inlinable
    public var base: Ownership.Borrow<Base> {
        @_lifetime(borrow self)
        _read { yield _storage.underlying }
    }
}

extension Property.Borrow where Base: ~Copyable & ~Escapable {
    /// Unsafely creates a read-only accessor using a raw address, with
    /// lifetime based on the borrowed owner.
    ///
    /// This is the only construction path available when `Base` is `~Escapable`,
    /// because the typed `init(_ base: borrowing Base)` delegates through
    /// `Ownership.Borrow(borrowing:)`, which uses `withUnsafePointer(to:)`
    /// — gated `where Base: Escapable`. Mirrors
    /// ``Ownership/Borrow/init(unsafeRawAddress:borrowing:)``
    /// (the underlying storage init) — same shape, composed through Tagged.
    ///
    /// > Important: This init is compile-time-admission scaffolding plus a
    /// > runtime construction path for callers that supply `pointer` from a
    /// > **non-self** source — a pre-existing `UnsafeRawPointer` field,
    /// > kernel-mapped memory, file-mapped storage, or any external pointer
    /// > source independent of the `borrowing owner`. The view-of-self
    /// > consumer pattern from a non-mutating `_read` accessor on
    /// > `Self: ~Copyable & ~Escapable` is **uncompilable**:
    /// > `withUnsafePointer(to:)` is Escapable-gated, and there is no
    /// > user-package mechanism to derive `UnsafeRawPointer` from
    /// > `borrow self` where `Self: ~Escapable`. From a `mutating _read`,
    /// > the `Property<...>.Borrow(unsafeRawAddress: &self, borrowing: self)`
    /// > shape is also uncompilable (dual-`&self` exclusivity violation
    /// > between the implicit `inout T` → `UnsafeRawPointer` conversion
    /// > and a separate borrow on `self`; plus boundary-scoped pointer
    /// > lifetime).
    /// >
    /// > Producing a stable raw pointer to ~Escapable inout/borrow in
    /// > user-package code requires a Swift language affordance not
    /// > currently exposed: `Builtin.addressOfBorrow` (stdlib-internal),
    /// > or a future `~Escapable`-admitting `withUnsafePointer` variant,
    /// > or a `Reborrow<T>: ~Escapable`-style facility. The cohort tracks
    /// > this as DEFERRED-TOOLCHAIN — see
    /// > `swift-collection-primitives/Research/escapable-protocol-foreach-count-view.md`
    /// > v1.1.0 §J–§K.
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
