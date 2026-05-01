public import Property_Primitives_Core

extension Property where Base: ~Copyable {
    /// A property with an `Element` parameter for property-based extensions.
    ///
    /// `Property<Tag, Base>.Typed<Element>` carries `Element` in its generic signature
    /// so `var` extensions can bind to it in a where-clause.
    ///
    /// Canonical usage — adopt the library type via a foundational typealias,
    /// pair the phantom tag with its accessor in its own extension, and declare
    /// the namespace's typed properties on `Property.Typed` at module scope:
    ///
    /// ```swift
    /// extension Stack {
    ///     typealias Property<Tag> = Property_Primitives.Property<Tag, Stack<Element>>
    /// }
    ///
    /// extension Stack {
    ///     enum Peek {}
    ///
    ///     var peek: Property<Peek>.Typed<Element> {
    ///         Property<Peek>.Typed(self)
    ///     }
    /// }
    ///
    /// extension Property.Typed
    /// where Tag == Stack<Element>.Peek, Base == Stack<Element> {
    ///     var back: Element?  { base.last }
    ///     var front: Element? { base.first }
    ///     var count: Int      { base.count }
    /// }
    ///
    /// let last = stack.peek.back
    /// ```
    ///
    /// For worked examples and the language-asymmetry discussion, see the
    /// Property.Typed article in the `Property Typed Primitives` DocC catalog.
    /// For the broader type-family reference, see ``Property`` and the
    /// `Property_Primitives` umbrella catalog.
    public struct Typed<Element>: ~Copyable {
        // Note: Cannot use @Inlined here due to swiftlang/swift#81624
        // (SILGen crash with property wrapper + ~Copyable cross-module)
        @usableFromInline
        internal var _base: Base

        /// Creates a typed property wrapping the given base value.
        ///
        /// Counterpart to `Property/init(_:)`, parameterized by `Element` so that
        /// `var` extensions on `Property.Typed` can bind `Element` in their
        /// where-clauses. Consumes `base` by value.
        ///
        /// ## Example
        ///
        /// ```swift
        /// var peek: Property<Peek>.Typed<Element> {
        ///     Property<Peek>.Typed(self)
        /// }
        /// ```
        ///
        /// - Parameter base: The value to wrap. Consumed by the initializer.
        @inlinable
        public init(_ base: consuming Base) {
            self._base = base
        }
    }
}

extension Property.Typed where Base: ~Copyable {
    @inlinable
    public var base: Base {
        _read { yield _base }
        _modify { yield &_base }
    }
}

extension Property.Typed: Copyable where Base: Copyable {}
extension Property.Typed: Sendable where Base: Sendable {}
