/// An owned property for CoW-safe mutation namespacing.
///
/// `Property<Tag, Base>` wraps a base value for fluent accessor namespaces. The phantom
/// `Tag` discriminates which extensions apply, so one container can expose multiple
/// namespaces (`push`, `pop`, `peek`) each with its own extension surface.
///
/// Canonical usage — adopt the library type via a foundational typealias, then
/// pair each phantom tag with its accessor in its own extension, and declare
/// the namespace's methods on `Property` at module scope:
///
/// ```swift
/// extension Stack {
///     typealias Property<Tag> = Property_Primitives.Property<Tag, Stack<Element>>
/// }
///
/// extension Stack {
///     enum Push {}
///
///     var push: Property<Push> {
///         _read { yield Property<Push>(self) }
///         _modify {
///             makeUnique()
///             var property: Property<Push> = .init(self)
///             self = Stack()
///             defer { self = property.base }
///             yield &property
///         }
///     }
/// }
///
/// extension Property {
///     mutating func back<E>(_ element: E)
///     where Tag == Stack<E>.Push, Base == Stack<E> {
///         base.append(element)
///     }
/// }
///
/// stack.push.back(element)
/// ```
///
/// For property extensions (not just methods), use `Property.Typed` (in
/// `Property Typed Primitives`). For `~Copyable` containers, use
/// `Property.View` (in `Property View Primitives`). For the full type
/// family and decision guidance, see the `Property_Primitives` umbrella
/// catalog.
public struct Property<Tag, Base: ~Copyable>: ~Copyable {
    // Note: Cannot use @Inlined here due to swiftlang/swift#81624
    // (SILGen crash with property wrapper + ~Copyable cross-module)
    @usableFromInline
    internal var _base: Base

    /// Creates a property wrapping the given base value.
    ///
    /// The initializer consumes `base` by value. For `Copyable` bases, consumption
    /// triggers an implicit copy when needed; for `~Copyable` bases, ownership is
    /// transferred into the property. Used as step 3 of the CoW-safe `_modify`
    /// recipe on `Copyable` accessors.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var property: Property<Push> = .init(self)
    /// ```
    ///
    /// - Parameter base: The value to wrap. Consumed by the initializer.
    @inlinable
    public init(_ base: consuming Base) {
        self._base = base
    }
}

extension Property where Base: ~Copyable {
    @inlinable
    public var base: Base {
        _read { yield _base }
        _modify { yield &_base }
    }
}

extension Property: Copyable where Base: Copyable {}
extension Property: Sendable where Base: Sendable {}
