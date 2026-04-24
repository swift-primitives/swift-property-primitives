public import Property_Primitives_Core

extension Property.View.Typed where Base: ~Copyable, Element: ~Copyable {
    /// A ``Property/View-swift.struct/Typed`` with one value-generic parameter.
    ///
    /// `Property<Tag, Base>.View.Typed<Element>.Valued<n>` lifts a compile-time integer
    /// (e.g. `capacity`, `N`) to the type level so extension where-clauses can bind it
    /// alongside `Element` and `Base`.
    ///
    /// Canonical usage — `~Copyable` container with one value generic:
    ///
    /// ```swift
    /// extension Array.Inline where Element: ~Copyable {
    ///     typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
    ///
    ///     var forEach: Property<Sequence.ForEach>.View.Typed<Element>.Valued<capacity> {
    ///         mutating _read  { yield unsafe .init(&self) }
    ///         mutating _modify {
    ///             var view: Property<Sequence.ForEach>.View.Typed<Element>.Valued<capacity> = unsafe .init(&self)
    ///             yield &view
    ///         }
    ///     }
    /// }
    ///
    /// extension Property_Primitives.Property.View.Typed.Valued
    /// where Tag == Sequence.ForEach, Base == Array<Element>.Inline<n>,
    ///       Element: ~Copyable {
    ///     func callAsFunction(_ body: (borrowing Element) -> Void) {
    ///         // Both Element and n are in scope.
    ///     }
    /// }
    /// ```
    ///
    /// For two value generics, see ``Property/View-swift.struct/Typed/Valued/Valued``.
    /// The verbosity trade-off and the recommended tag-enum-`View` typealias pattern
    /// are documented in the Property.View.Typed.Valued article in the
    /// `Property View Primitives` DocC catalog.
    @safe
    public struct Valued<let n: Int>: ~Copyable, ~Escapable {
        @usableFromInline
        internal let _base: UnsafeMutablePointer<Base>

        /// Creates a valued view wrapping a pointer to the base value.
        ///
        /// - Parameter base: A pointer to the value to wrap.
        @inlinable
        @_lifetime(borrow base)
        public init(_ base: UnsafeMutablePointer<Base>) {
            unsafe _base = base
        }
    }
}

extension Property.View.Typed.Valued where Base: ~Copyable, Element: ~Copyable {
    @inlinable
    public var base: UnsafeMutablePointer<Base> {
        unsafe _base
    }
}
