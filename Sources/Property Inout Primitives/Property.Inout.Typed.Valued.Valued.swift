public import Ownership_Inout_Primitives
public import Property_Primitive
public import Tagged_Primitives

extension Property.Inout.Typed.Valued where Base: ~Copyable, Element: ~Copyable {

    @safe
    public struct Valued<let m: Int>: ~Copyable, ~Escapable {
        @usableFromInline
        internal var _storage: Tagged<Tag, Ownership.Inout<Base>>

        @_transparent
        @_lifetime(&base)
        public init(_ base: inout Base) {
            self._storage = Tagged(_unchecked: Ownership.Inout(mutating: &base))
        }
    }
}

extension Property.Inout.Typed.Valued.Valued where Base: ~Copyable, Element: ~Copyable {

    @inlinable
    public var base: Ownership.Inout<Base> {
        @_lifetime(borrow self)
        _read { yield _storage.underlying }
    }
}
