public import Property_Primitives_Core
public import Property_View_Primitives

extension Property.View.Read.Typed where Base: ~Copyable, Element: ~Copyable {
    /// A ``Property/View-swift.struct/Read/Typed`` with a value-generic parameter.
    ///
    /// `Property<Tag, Base>.View.Read.Typed<Element>.Valued<n>` is the read-only
    /// counterpart of ``Property/View-swift.struct/Typed/Valued`` — it lifts one
    /// compile-time integer (e.g. `N`) to the type level so extension where-clauses
    /// can bind it alongside `Element` and `Base`. The borrowing-init overload works
    /// from non-mutating contexts so `let`-bound `~Copyable` containers are call sites.
    ///
    /// Canonical usage — container with one value generic, read-only access:
    ///
    /// ```swift
    /// extension List.Linked where Element: ~Copyable {
    ///     typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
    ///
    ///     enum Peek {}
    ///
    ///     var peek: Property<Peek>.View.Read.Typed<Element>.Valued<N> {
    ///         _read {
    ///             yield unsafe Property<Peek>.View.Read.Typed<Element>.Valued<N>(self)
    ///         }
    ///     }
    /// }
    ///
    /// extension Property_Primitives.Property.View.Read.Typed.Valued
    /// where Tag == List<Element>.Linked<n>.Peek, Base == List<Element>.Linked<n>,
    ///       Element: ~Copyable {
    ///     func first<R>(_ body: (borrowing Element) -> R) -> R? {
    ///         // Element and n are in scope.
    ///     }
    /// }
    /// ```
    ///
    /// Switch to ``Property/View-swift.struct/Typed/Valued`` when mutation is needed.
    /// For the full pointer variant family and value-generic verbosity discussion,
    /// see the Property.View.Read.Typed.Valued article in the `Property View Read
    /// Primitives` DocC catalog.
    @safe
    public struct Valued<let n: Int>: ~Copyable, ~Escapable {
        @usableFromInline
        internal let _base: UnsafePointer<Base>

        /// Creates a valued read-only view wrapping a pointer to the base value.
        ///
        /// - Parameter base: A read-only pointer to the value to wrap.
        @inlinable
        @_lifetime(borrow base)
        public init(_ base: UnsafePointer<Base>) {
            unsafe _base = base
        }

        /// Creates a valued read-only view by borrowing the base value directly.
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

extension Property.View.Read.Typed.Valued where Base: ~Copyable, Element: ~Copyable {
    @inlinable
    public var base: UnsafePointer<Base> {
        unsafe _base
    }
}
