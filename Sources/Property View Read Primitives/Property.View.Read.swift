public import Property_Primitives_Core
public import Property_View_Primitives

extension Property.View where Base: ~Copyable {
    /// A read-only view on a `~Copyable` base via `UnsafePointer`.
    ///
    /// `Property<Tag, Base>.View.Read` mirrors ``Property/View-swift.struct`` but with
    /// `UnsafePointer` and read-only semantics. The borrowing-init overload obtains the
    /// pointer from non-mutating contexts (`_read`, `borrowing func`), so `let`-bound
    /// `~Copyable` containers work as call sites.
    ///
    /// Canonical usage — a non-mutating `_read` on a `~Copyable` container:
    ///
    /// ```swift
    /// extension Container where Self: ~Copyable {
    ///     typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
    ///
    ///     enum Inspect {}
    ///
    ///     var inspect: Property<Inspect>.View.Read {
    ///         _read {
    ///             yield unsafe Property<Inspect>.View.Read(self)
    ///         }
    ///     }
    /// }
    ///
    /// extension Property_Primitives.Property.View.Read
    /// where Tag == Container.Inspect, Base == Container {
    ///     var count: Int { unsafe base.pointee.count }
    /// }
    ///
    /// let size = container.inspect.count
    /// ```
    ///
    /// Use this variant for read-only namespaces; switch to ``Property/View-swift.struct``
    /// when extensions need to mutate or consume. For construction choices and worked
    /// examples, see the Property.View.Read article in the `Property View Read Primitives`
    /// DocC catalog.
    @safe
    public struct Read: ~Copyable, ~Escapable {
        @usableFromInline
        internal let _base: UnsafePointer<Base>

        /// Creates a read-only view wrapping a pointer to the base value.
        ///
        /// - Parameter base: A read-only pointer to the value to wrap.
        @inlinable
        @_lifetime(borrow base)
        public init(_ base: UnsafePointer<Base>) {
            unsafe _base = base
        }

        /// Creates a read-only view by borrowing the base value directly.
        ///
        /// Use from non-mutating `_read` accessors and `borrowing` functions.
        ///
        /// - Parameter base: The value to borrow.
        @_lifetime(borrow base)
        public init(_ base: borrowing Base) {
            unsafe _base = withUnsafePointer(to: base) { unsafe $0 }
        }
    }
}

extension Property.View.Read where Base: ~Copyable {
    @inlinable
    public var base: UnsafePointer<Base> {
        unsafe _base
    }
}
