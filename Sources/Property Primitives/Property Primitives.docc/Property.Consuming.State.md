# ``Property_Primitives/Property/Consuming/State``

@Metadata {
    @DisplayName("Property.Consuming.State")
    @TitleHeading("Swift Primitives")
}

Reference-type state tracker for conditional restoration.

## Overview

`Property.Consuming.State` holds the wrapped base (`_base: Base?`) and the
consumed flag (`_consumed: Bool`). It is the sole mutable storage of a
``Property/Consuming`` instance; both the owning property and the `defer`
block of a `_modify` accessor reference the same instance.

## Rationale

The state must be a reference type so that mutations through
``Property/Consuming/consume()`` are observable from the outer `defer` block
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

`Property.Consuming.State` is conditionally `Sendable` when `Base: Sendable`,
so that the outer ``Property/Consuming`` propagates Sendability through to
its callers without over-constraining instantiations whose `Base` is not
itself `Sendable`.

## Topics

### Construction

- ``Property/Consuming/State/init(_:)``

### Access

- ``Property/Consuming/State/borrow()``
- ``Property/Consuming/State/isConsumed``

## See Also

- ``Property/Consuming``
