public import Ownership_Inout
public import Property_Primitive
public import Tagged

extension Property.Inout where Base: ~Copyable {

    @safe
    public struct Typed<Element: ~Copyable>: ~Copyable, ~Escapable {
        @usableFromInline
        internal var _storage: Tagged<Tag, Ownership.Inout<Base>>

        @_transparent
        @_lifetime(&base)
        public init(_ base: inout Base) {
            self._storage = Tagged(_unchecked: Ownership.Inout(mutating: &base))
        }
    }
}

extension Property.Inout.Typed where Base: ~Copyable, Element: ~Copyable {

    @inlinable
    public var base: Ownership.Inout<Base> {
        @_lifetime(borrow self)
        _read { yield _storage.underlying }
    }
}
