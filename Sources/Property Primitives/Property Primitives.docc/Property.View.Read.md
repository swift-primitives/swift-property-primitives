# ``Property_Primitives/Property/View-swift.struct/Read``

@Metadata {
    @DisplayName("Property.View.Read")
    @TitleHeading("Swift Primitives")
}

A read-only view on a `~Copyable` base via `UnsafePointer`.

## Overview

`Property<Tag, Base>.View.Read` mirrors ``Property/View-swift.struct`` but
with `UnsafePointer` and read-only semantics. The borrowing-init overload
obtains the pointer from non-mutating contexts (`_read`, `borrowing func`),
so `let`-bound `~Copyable` containers work as call sites.

## Example

Non-mutating `_read` on a `~Copyable` container; works on `let` bindings:

```swift
extension Container where Self: ~Copyable {
    typealias Property<Tag> = Property_Primitives.Property<Tag, Self>

    enum Inspect {}

    var inspect: Property<Inspect>.View.Read {
        _read {
            yield unsafe Property<Inspect>.View.Read(self)  // borrowing-init, unlabeled
        }
    }
}

extension Property_Primitives.Property.View.Read
where Tag == Container.Inspect, Base == Container {
    var count: Int { unsafe base.pointee.count }
}

let container = Container()
let size = container.inspect.count                    // works on `let` bindings
```

## Rationale

The mutable ``Property/View-swift.struct`` requires `&self` to construct its
`UnsafeMutablePointer` — `&self` only exists in mutating contexts. That
makes the mutable View unreachable from non-mutating `_read` accessors, from
`borrowing` functions, and — most importantly — from `let`-bound `~Copyable`
containers at the call site (since `let` bindings cannot undergo mutation).

`Property.View.Read` uses `UnsafePointer<Base>` and obtains it via
`withUnsafePointer(to: base)` on the borrowing init. That function takes a
`borrowing` parameter (the stdlib wraps `Builtin.addressOfBorrow`
internally), so it does not require `&self` and works in non-mutating
contexts. The borrowing init — `init(_ base: borrowing Base)` — makes
`let container.inspect.count` a valid call site.

The split between mutable `View` and read-only `Read` is the decision
captured in `property-view-escapable-removal.md`. The two types exist
because `~Escapable` lifetime annotations alone did not solve pointer
acquisition from borrowed context; a separate type with its own
construction path was the smallest shape that covered the read-only access
mode while preserving the pointer-based performance profile.

The borrowing-init overload is called WITHOUT an argument label —
`Property.View.Read(self)`, not `Property.View.Read(borrowing: self)`. The
label was dropped in 0.1.0 because type-based overload resolution already
disambiguates the borrowing-init (takes `borrowing Base`) from the
pointer-init (takes `UnsafePointer<Base>`), and Swift provides no
expression-form `borrowing self` at call sites so the label couldn't offer
expression-level explicitness either.

## Topics

### Access

- ``Property/View-swift.struct/Read/base``

### Variants

- ``Property/View-swift.struct/Read/Typed``
- ``Property/View-swift.struct/Read/Typed/Valued``

## Research

- [Property.View ~Escapable Removal](../../../Research/property-view-escapable-removal.md) — Root cause, options analysis, and the decision to split mutable `View` from read-only `View.Read`. Status: DECISION.
- [Borrowing Label Drop Rationale](../../../Research/borrowing-label-drop-rationale.md) — Why `init(_ base: borrowing Base)` is called without the `borrowing:` label in 0.1.0. Status: DECISION.

## Experiments

- [borrowing-read-accessor-test](../../../Experiments/borrowing-read-accessor-test/) — v2: `withUnsafePointer(to: self)` works from non-mutating context on `~Copyable` types via `Builtin.addressOfBorrow(value)`. Pattern shipped as `init(_ base: borrowing Base)` across the Read family. Status: CONFIRMED.

## See Also

- ``Property/View-swift.struct``
- ``Property/View-swift.struct/Read/Typed``
