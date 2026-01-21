/// An owned property for CoW-safe mutation namespacing.
///
/// `Property` provides temporary ownership of a base value for namespaced operations.
/// Extensions are added via constraints on the phantom `Tag` type.
///
/// ## Property vs Property.View
///
/// - **Property** — Owns the base value. Used via `_modify` + defer for CoW types.
/// - **Property.View** — Borrows via pointer. Used via `_read` for `~Copyable` types.
///
/// ## Usage (Owned)
///
/// ```swift
/// extension Deque {
///     public enum Push {}
/// }
///
/// extension Deque where Element: Copyable {
///     public var push: Property<Deque<Element>, Deque<Element>.Push> {
///         _read { yield Property(self) }
///         _modify {
///             makeUnique()
///             var property = Property(self)
///             self = Deque()
///             defer { self = property.base }
///             yield &property
///         }
///     }
/// }
/// ```
///
/// ## Usage (Borrowed View)
///
/// ```swift
/// extension Input.Access.Random where Self: ~Copyable {
///     public var access: Property<Self, Input.Access>.View {
///         mutating _read {
///             yield unsafe Property.View(&self)
///         }
///     }
/// }
/// ```
public struct Property<Base: ~Copyable, Tag>: ~Copyable {
    @usableFromInline
    internal var _base: Base

    /// Creates a property wrapping the given base value.
    ///
    /// - Parameter base: The value to wrap.
    @inlinable
    public init(_ base: consuming Base) {
        self._base = base
    }

    /// The wrapped base value.
    @inlinable
    public var base: Base {
        _read { yield _base }
        _modify { yield &_base }
    }
}

extension Property: Copyable where Base: Copyable {}
extension Property: Sendable where Base: Sendable {}
