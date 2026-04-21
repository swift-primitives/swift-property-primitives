public import Property_Primitives_Core
public import Property_View_Primitives

extension Property.View.Read where Base: ~Copyable {
    /// A read-only view on a `~Copyable` base with an `Element` parameter.
    ///
    /// `Property<Tag, Base>.View.Read.Typed<Element>` is the read-only counterpart of
    /// ``Property/View-swift.struct/Typed``. The borrowing-init overload works from
    /// non-mutating `_read` accessors and `borrowing` functions, enabling `let`-bound
    /// `~Copyable` containers at the call site.
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
    ///             yield unsafe Property<Peek>.View.Read.Typed(self)
    ///         }
    ///     }
    /// }
    ///
    /// extension Property_Primitives.Property.View.Read.Typed
    /// where Tag == Container<Element>.Peek, Base == Container<Element>,
    ///       Element: ~Copyable
    /// {
    ///     var count: Int { unsafe base.pointee.storage.count }
    /// }
    ///
    /// let size = container.peek.count     // works on `let`-bound ~Copyable containers
    /// ```
    ///
    /// Switch to ``Property/View-swift.struct/Typed`` when extensions need mutation.
    /// For a value generic alongside `Element`, see
    /// ``Property/View-swift.struct/Read/Typed/Valued``.
    @safe
    public struct Typed<Element: ~Copyable>: ~Copyable, ~Escapable {
        @usableFromInline
        internal let _base: UnsafePointer<Base>

        /// Creates a typed read-only view wrapping a pointer to the base value.
        ///
        /// - Parameter base: A read-only pointer to the value to wrap.
        @inlinable
        @_lifetime(borrow base)
        public init(_ base: UnsafePointer<Base>) {
            unsafe _base = base
        }

        /// Creates a typed read-only view by borrowing the base value directly.
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

extension Property.View.Read.Typed where Base: ~Copyable, Element: ~Copyable {
    @inlinable
    public var base: UnsafePointer<Base> {
        unsafe _base
    }
}
