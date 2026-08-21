public struct Property<Tag: ~Copyable & ~Escapable, Base: ~Copyable>: ~Copyable {

    @usableFromInline
    internal var _base: Base

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

extension Property: Copyable where Tag: ~Copyable & ~Escapable, Base: Copyable {}
extension Property: Sendable where Tag: ~Copyable & ~Escapable, Base: Sendable {}
