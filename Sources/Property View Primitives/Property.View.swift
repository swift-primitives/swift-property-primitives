public import Property_Primitives_Core

extension Property where Base: ~Copyable {
    /// A view property for `~Copyable` types supporting borrowing and consuming access.
    ///
    /// `Property<Tag, Base>.View` wraps an `UnsafeMutablePointer<Base>` and enables the
    /// same fluent accessor syntax used for `Copyable` containers. Mutating `_read` and
    /// `_modify` accessors yield the view so extensions can read (`func`) or clear
    /// through the pointer (`mutating func`) without ownership transfer.
    ///
    /// Canonical usage — from a `mutating _read` / `_modify` on a `~Copyable` container:
    ///
    /// ```swift
    /// extension Buffer where Element: ~Copyable {
    ///     typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
    ///
    ///     enum Insert {}
    ///
    ///     var insert: Property<Insert>.View {
    ///         mutating _read {
    ///             yield unsafe Property<Insert>.View(&self)
    ///         }
    ///         mutating _modify {
    ///             var view = unsafe Property<Insert>.View(&self)
    ///             yield &view
    ///         }
    ///     }
    /// }
    ///
    /// extension Property_Primitives.Property.View
    /// where Tag == Buffer<Element>.Insert, Base == Buffer<Element>,
    ///       Element: ~Copyable {
    ///     mutating func front(_ element: consuming Element) {
    ///         unsafe base.pointee.push(front: element)
    ///     }
    /// }
    ///
    /// buffer.insert.front(element)
    /// ```
    ///
    /// From non-mutating contexts (`Sequence.makeIterator()`, subscript getters), use the
    /// static ``pointer(to:_:)`` helpers on stored properties, or `Property.View.Read`
    /// (in `Property View Read Primitives`) if mutation isn't needed.
    ///
    /// For accessor-context trade-offs, `~Escapable` history, and the full pointer
    /// variant family, see the Property.View article in the `Property View Primitives`
    /// DocC catalog. For the broader type-family reference, see ``Property``.
    @safe
    public struct View: ~Copyable, ~Escapable {
        @usableFromInline
        internal let _base: UnsafeMutablePointer<Base>

        /// Creates a view wrapping a pointer to the base value.
        ///
        /// - Parameter base: A pointer to the value to wrap.
        @inlinable
        @_lifetime(borrow base)
        public init(_ base: UnsafeMutablePointer<Base>) {
            unsafe _base = base
        }

        /// Creates a view by borrowing the base value directly.
        ///
        /// Use from non-mutating `_read` accessors and `borrowing` functions.
        ///
        /// This is `@unsafe` because it casts away const — the caller must
        /// ensure mutation through the pointer is valid (e.g., in `deinit`
        /// where the value is being consumed).
        ///
        /// - Parameter base: The value to borrow.
        @unsafe
        @_lifetime(borrow base)
        public init(_ base: borrowing Base) {
            unsafe _base = UnsafeMutablePointer(mutating: withUnsafePointer(to: base) { unsafe $0 })
        }

        // MARK: - Static Access for Non-Mutating Contexts

        /// Perform a read operation with a pointer to a stored property.
        ///
        /// Use this when you need pointer access from a non-mutating context
        /// (e.g., `makeIterator()`, subscript getters, `borrowing` functions).
        ///
        /// ## Example: Iterator Creation
        ///
        /// ```swift
        /// struct SmallArray<Element>: Sequence {
        ///     typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
        ///
        ///     enum Inline {}
        ///
        ///     var _inlineStorage: (Element?, Element?, Element?, Element?)
        ///     var _count: Int
        ///
        ///     // makeIterator must be non-mutating per Sequence protocol
        ///     borrowing func makeIterator() -> Iterator {
        ///         Property<Inline>.View.pointer(to: _inlineStorage) { ptr in
        ///             Iterator(base: ptr, count: _count)
        ///         }
        ///     }
        /// }
        /// ```
        ///
        /// ## Limitations
        ///
        /// - The pointer is only valid within the closure body
        /// - Cannot return the pointer or types containing it directly
        /// - For types that need to escape, copy the data out within the closure
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
        /// Use this when you need mutable pointer access to a stored property.
        /// Requires the property to be passed as `inout`.
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
}

extension Property.View where Base: ~Copyable {
    @inlinable
    public var base: UnsafeMutablePointer<Base> {
        unsafe _base
    }
}
