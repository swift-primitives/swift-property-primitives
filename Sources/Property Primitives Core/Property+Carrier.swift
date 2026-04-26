// Property+Carrier.swift
// Property<Tag, Base> conforms to Carrier as a phantom-typed wrapper —
// the Q2/Q4 (~Copyable) sibling to `Tagged<Tag, RawValue>`'s Q1/Q3 role.
//
// Together with `Tagged: Carrier`, this conformance unifies Property and
// Tagged in the Carrier family across all four Copyable × Escapable
// quadrants. APIs declared as `func f<C: Carrier>(_ c: C)` accept
// values of either container uniformly.
//
// `Domain = Tag` (the phantom discriminator).
// `Underlying = Base` (the wrapped value type).
//
// `var underlying` is a `_read` coroutine yielding the stored `_base`,
// matching Carrier's `borrowing get` requirement for both Copyable and
// ~Copyable Underlying.
//
// `init(_ underlying: consuming Base)` is satisfied by Property's
// existing `init(_ base: consuming Base)` — same signature.

public import Carrier_Primitives

extension Property: Carrier where Base: ~Copyable {
    /// The wrapped value type.
    public typealias Underlying = Base

    /// The phantom `Tag` IS the Carrier's `Domain`.
    public typealias Domain = Tag

    /// Borrowing access to the underlying value.
    @inlinable
    public var underlying: Base {
        _read { yield _base }
    }
}
