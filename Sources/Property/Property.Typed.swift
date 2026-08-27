
extension Property where Base: ~Copyable {

    public struct Typed<Element>: ~Copyable {

        @usableFromInline
        internal var _base: Base

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
