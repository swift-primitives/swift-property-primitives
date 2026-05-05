# ``Property_Primitives/Property/Borrow/Typed/Valued``

@Metadata {
    @DisplayName("Property.Borrow.Typed.Valued")
    @TitleHeading("Swift Primitives")
}

A ``Property/Borrow/Typed`` with a value-generic parameter.

## Overview

`Property<Tag, Base>.Borrow.Typed<Element>.Valued<n>` is the read-only
counterpart of `Property.Inout.Typed.Valued` (in `Property Inout
Primitives`) — it lifts one compile-time integer (e.g. `N`) to the type
level so extension where-clauses can bind it alongside `Element` and
`Base`. The borrowing-init works from non-mutating contexts, so
`let`-bound `~Copyable` containers are valid call sites.

## Example

Adopt the library type via a foundational typealias on the container, pair the
phantom tag with its accessor in its own extension, and declare the namespace's
methods on `Property.Borrow.Typed.Valued` at module scope:

```swift
extension List.Linked where Element: ~Copyable {
    typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
}

extension List.Linked where Element: ~Copyable {
    enum Peek {}

    var peek: Property<Peek>.Borrow.Typed<Element>.Valued<N> {
        _read {
            yield Property<Peek>.Borrow.Typed<Element>.Valued<N>(self)
        }
    }
}

extension Property.Borrow.Typed.Valued
where Tag == List<Element>.Linked<n>.Peek, Base == List<Element>.Linked<n>,
      Element: ~Copyable {
    func first<R>(_ body: (borrowing Element) -> R) -> R? {
        // Element and n are in scope.
    }
}
```

## Rationale

The `.Valued<n>` suffix lifts one value generic to the type level, making it
available in extension where-clauses. The read-only counterpart uses the
same mechanism as the mutable `Property.Inout.Typed.Valued` (in
`Property Inout Primitives`), swapping `Ownership.Inout` for
`Ownership.Borrow` and the mutating construction paths for the borrowing
init.

There is no `Borrow.Typed.Valued.Valued` in the current Borrow family — read-only
access on two-value-generic containers currently routes through the mutable
path (mutable accessors with read-only extensions) or through custom
projection. The absence is deliberate pending concrete consumer demand.

The recommended tag-enum-`Accessor` typealias pattern documented for the mutable
family applies here verbatim; see the "Value-Generic Verbosity and the
Tag-Enum-Accessor Pattern" article in the `Property_Primitives` umbrella
catalog for the canonical pattern.

Switch to `Property.Inout.Typed.Valued` (in `Property Inout Primitives`)
when mutation is needed.

## Topics

### Access

- ``Property/Borrow/Typed/Valued/base``

## See Also

- ``Property/Borrow/Typed``
- ``Property/Borrow``
