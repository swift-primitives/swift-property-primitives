# ``Property_Primitives/Property/Consume/State``

@Metadata {
    @DisplayName("Property.Consume.State")
    @TitleHeading("Swift Primitives")
}

Reference-type state tracker for conditional restoration.

## Overview

`Property.Consume.State` holds the wrapped base (`nil` once consumed) and the
consumed flag together, in one lock-guarded storage struct so that the two
fields transition as a unit. It is the sole mutable storage of a
``Property/Consume`` instance; both the owning property and the `defer`
block of a `_modify` accessor reference the same instance.

## Rationale

The state must be a reference type so that mutations through
``Property/Consume/consume()`` are observable from the outer `defer` block
after the method returns. Three invariants follow from reference semantics:

1. The `mutating func consuming()` on the extension sets
   `_consumed = true` via `consume()`.
2. The `defer` block on the outer `_modify` observes this change *after* the
   mutation returns.
3. The base can be extracted for restoration iff `_consumed == false` and
   `_base != nil`.

A value-type state would not carry the consume-bit across the yield/defer
boundary — the `defer` block would see the pre-mutation value and
unconditionally restore, undoing the consume.

`Property.Consume.State` is conditionally `Sendable` when `Base: Sendable`,
so that the outer ``Property/Consume`` propagates Sendability through to
its callers without over-constraining instantiations whose `Base` is not
itself `Sendable`.

## Ownership transfer

``Property/Consume/State/init(_:)`` takes `consuming Base`, not
`consuming sending Base`. The distinction matters because the accessor
pattern that ``Property/Consume`` documents wraps the enclosing `self`, and
`self` inside a property accessor is task-isolated — it is never a
disconnected value, so a `sending` parameter could not accept it for any
non-Sendable `Base`.

Requiring only `consuming` is sound because the conditional `Sendable`
conformance above is what governs cross-isolation reachability: for a
non-Sendable `Base` the resulting state is not `Sendable`, so it stays in
the caller's isolation region and its contents never cross a boundary. The
lock's own `sending` requirement on its payload is discharged inside the
type, by the internal storage struct's `@unchecked Sendable` conformance,
rather than being pushed out onto every call site.

## Topics

### Construction

- ``Property/Consume/State/init(_:)``

### Access

- ``Property/Consume/State/borrow()``
- ``Property/Consume/State/isConsumed``

## See Also

- ``Property/Consume``
