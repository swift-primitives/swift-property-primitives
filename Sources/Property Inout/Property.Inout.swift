@_exported public import Ownership_Inout
public import Property
public import Tagged

extension Property::Property where Base: ~Copyable {

    @safe
    public struct Inout: ~Copyable, ~Escapable {
        @usableFromInline
        internal var _storage: Tagged<Tag, Ownership.Inout<Base>>

        @_transparent
        @_lifetime(&base)
        public init(_ base: inout Base) {
            self._storage = Tagged(_unchecked: Ownership.Inout(mutating: &base))
        }

        @unsafe
        @_lifetime(borrow base)
        public init(_ base: borrowing Base) {
            let ptr = unsafe UnsafeMutablePointer<Base>(
                mutating: withUnsafePointer(to: base) { unsafe $0 }
            )
            let inoutRef = unsafe Ownership.Inout(ptr)
            let tagged = Tagged<Tag, Ownership.Inout<Base>>(_unchecked: inoutRef)
            unsafe (self._storage = _overrideLifetime(tagged, borrowing: base))
        }
    }
}

extension Property::Property.Inout where Base: ~Copyable {

    @inlinable
    public var base: Ownership.Inout<Base> {
        @_lifetime(borrow self)
        _read { yield _storage.underlying }
    }
}

extension Property::Property where Base: ~Copyable {

    @inlinable
    public static func pointer<T, R>(
        to property: borrowing T,
        _ body: (UnsafePointer<T>) -> R
    ) -> R {
        withUnsafePointer(to: property, body)
    }

    @inlinable
    public static func pointer<T, R>(
        to property: inout T,
        mutating body: (UnsafeMutablePointer<T>) -> R
    ) -> R {
        withUnsafeMutablePointer(to: &property, body)
    }
}
