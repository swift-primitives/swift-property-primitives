# ``Property_Primitives/Property/Borrow``

@Metadata {
    @DisplayName("Property.Borrow")
    @TitleHeading("Swift Primitives")
}

A read-only accessor on a `~Copyable` base.

## Overview

`Property<Tag, Base>.Borrow` wraps a `Tagged<Tag, Ownership.Borrow<Base>>` —
a phantom-tagged shared immutable reference. Access goes through
`base.value`, which uses `Ownership.Borrow`'s `_read` accessor. The
non-mutating `_read` accessor obtains the borrow from `borrowing` contexts
(`_read`, `borrowing func`), so `let`-bound `~Copyable` containers work as
call sites.

## Example

Adopt the library type via a foundational typealias on the container, pair the
phantom tag with its accessor in its own extension, and declare the namespace's
properties on `Property.Borrow` at module scope. Works on `let` bindings:

```swift
extension Container where Self: ~Copyable {
    typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
}

extension Container where Self: ~Copyable {
    enum Inspect {}

    var inspect: Property<Inspect>.Borrow {
        _read {
            yield Property<Inspect>.Borrow(self)
        }
    }
}

extension Property.Borrow
where Tag == Container.Inspect, Base == Container {
    var count: Int { base.value.count }
}

let container = Container()
let size = container.inspect.count                    // works on `let` bindings
```

## Rationale

The mutable ``Property/Inout-swift.struct`` requires `&self` to construct its
`Ownership.Inout` — `&self` only exists in mutating contexts. That makes
the mutable Inout unreachable from non-mutating `_read` accessors, from
`borrowing` functions, and — most importantly — from `let`-bound `~Copyable`
containers at the call site (since `let` bindings cannot undergo mutation).

`Property.Borrow` uses `Ownership.Borrow<Base>` and obtains it via
`Ownership.Borrow(borrowing: base)` on a borrowing init. The init takes a
`borrowing` parameter, so it does not require `&self` and works in
non-mutating contexts. The init — `init(_ base: borrowing Base)` — makes
`let container.inspect.count` a valid call site.

The split between mutable `Inout` and read-only `Borrow` is the decision
captured in `property-view-escapable-removal.md` and refined in
`nested-view-vs-borrowed-naming.md`. The two types exist because the
borrow-vs-mutable distinction is fundamental: Inout requires `&self` for
its safe init; Borrow does not. A separate type with its own construction
path was the smallest shape that covered the read-only access mode while
preserving the typed-borrow performance profile.

The init takes a `borrowing` parameter directly — `Property.Borrow(self)`.
Type-based overload resolution is not needed because Borrow ships a single
safe init: there is no mutable counterpart to disambiguate against.

## Topics

### Access

- ``Property/Borrow/base``

### Variants

- ``Property/Borrow/Typed``
- ``Property/Borrow/Typed/Valued``

## See Also

- ``Property/Inout-swift.struct``
- ``Property/Borrow/Typed``
