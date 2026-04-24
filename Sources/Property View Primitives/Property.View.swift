public import Property_Primitives_Core
@_exported public import Ownership_Inout_Primitives
public import Tagged_Primitives

extension Property where Base: ~Copyable {
    /// A view property for `~Copyable` types supporting borrowing and mutable access.
    ///
    /// `Property<Tag, Base>.View` is a thin wrapper over
    /// `Tagged<Tag, Ownership.Inout<Base>>` — the phantom-tagged exclusive
    /// mutable reference composition from `Tagged_Primitives` and
    /// `Ownership_Primitives`. The storage realises the structural identity:
    /// a namespaced accessor for a `~Copyable` container is a tagged exclusive
    /// borrow. The wrapper preserves the `base` accessor name at the call site —
    /// extensions read and mutate through `base.value`, which uses
    /// `Ownership.Inout`'s safe `_read` / `nonmutating _modify` accessors.
    ///
    /// Canonical usage — from a `mutating _read` / `_modify` on a `~Copyable`
    /// container:
    ///
    /// ```swift
    /// extension Buffer where Element: ~Copyable {
    ///     typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
    ///
    ///     enum Insert {}
    ///
    ///     var insert: Property<Insert>.View {
    ///         mutating _read  { yield .init(&self) }
    ///         mutating _modify {
    ///             var view = Property<Insert>.View(&self)
    ///             yield &view
    ///         }
    ///     }
    /// }
    ///
    /// extension Property_Primitives.Property.View
    /// where Tag == Buffer<Element>.Insert, Base == Buffer<Element>,
    ///       Element: ~Copyable {
    ///     mutating func front(_ element: consuming Element) {
    ///         base.value.push(front: element)
    ///     }
    /// }
    ///
    /// buffer.insert.front(element)
    /// ```
    ///
    /// Access goes through `base.value` — no `unsafe` marker is needed;
    /// `Ownership.Inout` is `@safe` and the lifetime is compiler-enforced via
    /// `~Escapable`.
    ///
    /// For non-mutating contexts (`Sequence.makeIterator()`, subscript getters),
    /// use `Property.View.Read` (in `Property View Read Primitives`).
    ///
    /// For the broader type-family reference, see ``Property``.
    @safe
    public struct View: ~Copyable, ~Escapable {
        @usableFromInline
        internal var _storage: Tagged<Tag, Ownership.Inout<Base>>

        /// Creates a view by borrowing the base value exclusively.
        ///
        /// - Parameter base: The value to borrow mutably.
        @inlinable
        @_lifetime(&base)
        public init(_ base: inout Base) {
            self._storage = Tagged(__unchecked: (),
                                   Ownership.Inout(mutating: &base))
        }

        /// Creates a view by borrowing the base value from an immutable context.
        ///
        /// Use from non-mutating `_read` accessors and `borrowing` functions
        /// (notably `deinit`, where `self` is immutable but the value is being
        /// consumed).
        ///
        /// This is `@unsafe` because it casts away const — the caller must
        /// ensure mutation through the view is valid at the call site.
        ///
        /// > Warning: Do NOT add `@inlinable` to this init. The same Swift
        /// > 6.3.1 / 6.4-dev release-mode miscompile documented on
        /// > `Ownership.Borrow.init(borrowing:) where Value: ~Copyable`
        /// > applies here: when inlined across a module boundary,
        /// > `withUnsafePointer(to: base) { $0 }` begins returning a
        /// > callee-frame spill slot that dies when the closure returns.
        /// > Keeping this init non-`@inlinable` preserves the cross-module
        /// > function-call boundary and the `@in_guaranteed` indirect ABI.
        /// > Evidence at
        /// > `swift-institute/Experiments/borrow-pointer-storage-release-miscompile/`
        /// > and
        /// > `swift-institute/Audits/borrow-pointer-storage-release-miscompile.md`.
        /// > Same-module consumers (consumers in the
        /// > `Property View Primitives` module itself) cannot call this
        /// > init safely in release mode; they must use the
        /// > `init(_ base: inout Base)` overload or wrap the call in
        /// > `withUnsafePointer(to:)` and pass the typed pointer through
        /// > a separate construction path.
        ///
        /// - Parameter base: The value to borrow.
        @unsafe
        @_lifetime(borrow base)
        public init(_ base: borrowing Base) {
            let ptr = unsafe UnsafeMutablePointer<Base>(
                mutating: withUnsafePointer(to: base) { unsafe $0 }
            )
            let inoutRef = unsafe Ownership.Inout(ptr)
            let tagged = Tagged<Tag, Ownership.Inout<Base>>(__unchecked: (),
                                                            unsafe inoutRef)
            self._storage = unsafe _overrideLifetime(tagged, borrowing: base)
        }
    }
}

extension Property.View where Base: ~Copyable {
    /// The exclusive mutable reference to the base value.
    ///
    /// Use `base.value` to read or mutate the underlying value. Mutation flows
    /// through `Ownership.Inout`'s `nonmutating _modify` accessor, so a borrow
    /// of `base` is sufficient for both reads and writes.
    @inlinable
    public var base: Ownership.Inout<Base> {
        @_lifetime(borrow self)
        _read { yield _storage.rawValue }
    }
}

// MARK: - Non-mutating pointer helpers

extension Property where Base: ~Copyable {
    /// Perform a read operation with a pointer to a stored property.
    ///
    /// Use this when you need pointer access from a non-mutating context
    /// (e.g., `makeIterator()`, subscript getters, `borrowing` functions).
    ///
    /// - Parameters:
    ///   - property: A stored property to obtain a pointer to.
    ///   - body: A closure that receives the pointer and returns a result.
    /// - Returns: The result of the closure.
    @inlinable
    public static func pointer<T, R>(
        to property: borrowing T,
        _ body: (UnsafePointer<T>) -> R
    ) -> R {
        unsafe withUnsafePointer(to: property, body)
    }

    /// Perform a read operation with a mutable pointer to a stored property.
    ///
    /// - Parameters:
    ///   - property: A stored property to obtain a mutable pointer to.
    ///   - body: A closure that receives the mutable pointer and returns a result.
    /// - Returns: The result of the closure.
    @inlinable
    public static func pointer<T, R>(
        to property: inout T,
        mutating body: (UnsafeMutablePointer<T>) -> R
    ) -> R {
        unsafe withUnsafeMutablePointer(to: &property, body)
    }
}
