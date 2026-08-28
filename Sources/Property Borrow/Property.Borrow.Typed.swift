public import Ownership_Borrow
public import Property_Primitive
public import Tagged

extension Property.Borrow where Base: ~Copyable {

    @safe
    public struct Typed<Element: ~Copyable>: ~Copyable, ~Escapable {
        @usableFromInline
        internal var _storage: Tagged<Tag, Ownership.Borrow<Base>>

        @inlinable
        @_lifetime(borrow base)
        public init(_ base: borrowing Base) {
            self._storage = Tagged(_unchecked: Ownership.Borrow(borrowing: base))
        }
    }
}

extension Property.Borrow.Typed where Base: ~Copyable, Element: ~Copyable {

    @inlinable
    public var base: Ownership.Borrow<Base> {
        @_lifetime(borrow self)
        _read { yield _storage.underlying }
    }
}
