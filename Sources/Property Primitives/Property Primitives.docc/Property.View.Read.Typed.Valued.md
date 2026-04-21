# ``Property_Primitives/Property/View-swift.struct/Read/Typed/Valued``

@Metadata {
    @DisplayName("Property.View.Read.Typed.Valued")
    @TitleHeading("Swift Primitives")
}

A ``Property/View-swift.struct/Read/Typed`` with a value-generic parameter.

## Overview

`Property<Tag, Base>.View.Read.Typed<Element>.Valued<n>` is the read-only
counterpart of `Property.View.Typed.Valued` (in `Property View
Primitives`) — it lifts one compile-time integer (e.g. `N`) to the type
level so extension where-clauses can bind it alongside `Element` and
`Base`. The borrowing-init overload works from non-mutating contexts, so
`let`-bound `~Copyable` containers are valid call sites.

## Example

Container with one value generic, read-only access:

```swift
extension List.Linked where Element: ~Copyable {
    typealias Property<Tag> = Property_Primitives.Property<Tag, Self>

    enum Peek {}

    var peek: Property<Peek>.View.Read.Typed<Element>.Valued<N> {
        _read {
            yield unsafe Property<Peek>.View.Read.Typed<Element>.Valued<N>(self)
        }
    }
}

extension Property_Primitives.Property.View.Read.Typed.Valued
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
same mechanism as the mutable `Property.View.Typed.Valued` (in
`Property View Primitives`), swapping `UnsafeMutablePointer` for
`UnsafePointer` and the mutating construction paths for the borrowing
init.

There is no `Read.Typed.Valued.Valued` in the current Read family — read-only
access on two-value-generic containers currently routes through the mutable
path (mutable accessors with read-only extensions) or through custom
projection. The absence is deliberate pending concrete consumer demand.

The recommended tag-enum-`View` typealias pattern documented for the mutable
family applies here verbatim; see the "Value-Generic Verbosity and the
Tag-Enum-View Pattern" article in the `Property_Primitives` umbrella
catalog for the canonical pattern.

Switch to `Property.View.Typed.Valued` (in `Property View Primitives`)
when mutation is needed.

## Topics

### Access

- ``Property/View-swift.struct/Read/Typed/Valued/base``

## Research

- [Property.View .Valued.Valued Verbosity](../../../Research/property-view-valued-verbosity.md) — The tag-enum-`View` pattern applies identically to Read variants. Status: RECOMMENDATION.

## Experiments

- [valued-verbosity-best-of-all-worlds](../../../Experiments/valued-verbosity-best-of-all-worlds/) — V10 canonical pattern applies to Read as well as mutable. Status: SUPERSEDED (pattern shipped).

## See Also

- ``Property/View-swift.struct/Read/Typed``
- ``Property/View-swift.struct/Read``
