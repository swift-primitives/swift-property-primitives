# ``Property_Primitives/Property/View-swift.struct/Typed/Valued/Valued``

@Metadata {
    @DisplayName("Property.View.Typed.Valued.Valued")
    @TitleHeading("Swift Primitives")
}

A ``Property/View-swift.struct/Typed/Valued`` with a second value-generic
parameter.

## Overview

`Property<Tag, Base>.View.Typed<Element>.Valued<n>.Valued<m>` lifts two
compile-time integers to the type level so extension where-clauses can bind
both alongside `Element` and `Base`. Required when containers carry two
value generics, e.g. `Buffer<Element>.Linked<N>.Inline<capacity>`.

## Example

Two value generics in scope:

```swift
extension Buffer.Linked.Inline where Element: ~Copyable {
    var insert: Property<Buffer<Element>.Linked<N>.Insert, Self>
        .View.Typed<Element>.Valued<N>.Valued<capacity>
    {
        mutating _read  { yield unsafe .init(&self) }
        mutating _modify {
            var view: Property<Buffer<Element>.Linked<N>.Insert, Self>
                .View.Typed<Element>.Valued<N>.Valued<capacity> = unsafe .init(&self)
            yield &view
        }
    }
}

extension Property.View.Typed.Valued.Valued
where Tag == Buffer<Element>.Linked<n>.Insert,
      Base == Buffer<Element>.Linked<n>.Inline<m>,
      Element: ~Copyable {
    mutating func front(_ element: consuming Element) throws(Error) { }
}
```

## Rationale

Each `.Valued<n>` suffix lifts one value generic to the type level.
Containers with two value generics (e.g. node count `N` plus per-node
capacity `m`) need two suffixes. The `.Valued<n>.Valued<m>` chain preserves
positional meaning: the first `n` binds the first generic, the second `m`
binds the second.

Separate extensions with `Element: Copyable` provide the `Copyable`-only
variants (typically non-throwing) where the copy-vs-consume distinction is
absent. The throwing signature is load-bearing for `~Copyable` element
consumption: errors during mutation must be propagated rather than dropped,
because a `~Copyable` value passed to a failing `consume(_:)` has no owner
to return to.

Without the chain, extension where-clauses cannot bind both value generics
simultaneously. Method-level generic clauses create implicit `Copyable`
constraints that break `~Copyable` support. The two-suffix chain is the
smallest type-level encoding that carries both values while preserving
ownership mode.

The recommended tag-enum-`View` typealias pattern localises the verbosity
to a single declaration per accessor. See the "Value-Generic Verbosity and
the Tag-Enum-View Pattern" article in the `Property_Primitives` umbrella
catalog for the full canonical pattern; buffer-primitives ships it across
333 tests.

## Topics

### Construction

- ``Property/View-swift.struct/Typed/Valued/Valued/init(_:)``

### Access

- ``Property/View-swift.struct/Typed/Valued/Valued/base``

## Research

- [Property.View .Valued.Valued Verbosity](../../../Research/property-view-valued-verbosity.md) — Full trade-off analysis of the two-value-generic chain. Status: RECOMMENDATION.

## Experiments

- [view-typed-overload-coexistence](../../../Experiments/view-typed-overload-coexistence/) — Validates `.Valued<N>.Valued<m>` composes correctly for two-value-generic containers. Status: SUPERSEDED (pattern shipped).

## See Also

- ``Property/View-swift.struct/Typed/Valued``
- ``Property/View-swift.struct/Typed``
