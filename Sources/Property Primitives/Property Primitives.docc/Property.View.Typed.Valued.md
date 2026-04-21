# ``Property_Primitives/Property/View-swift.struct/Typed/Valued``

@Metadata {
    @DisplayName("Property.View.Typed.Valued")
    @TitleHeading("Swift Primitives")
}

A ``Property/View-swift.struct/Typed`` with one value-generic parameter.

## Overview

`Property<Tag, Base>.View.Typed<Element>.Valued<n>` lifts a compile-time
integer (e.g. `capacity`, `N`) to the type level so extension where-clauses
can bind it alongside `Element` and `Base`.

## Example

`~Copyable` container with one value generic:

```swift
extension Array.Inline where Element: ~Copyable {
    typealias Property<Tag> = Property_Primitives.Property<Tag, Self>

    var forEach: Property<Sequence.ForEach>.View.Typed<Element>.Valued<capacity> {
        mutating _read  { yield unsafe .init(&self) }
        mutating _modify {
            var view: Property<Sequence.ForEach>.View.Typed<Element>.Valued<capacity> = unsafe .init(&self)
            yield &view
        }
    }
}

extension Property_Primitives.Property.View.Typed.Valued
where Tag == Sequence.ForEach, Base == Array<Element>.Inline<n>,
      Element: ~Copyable {
    func callAsFunction(_ body: (borrowing Element) -> Void) {
        // Both Element and n are in scope.
    }
}
```

## Rationale

Value generics lifted to the type level (`.Valued<n>`) can appear in
extension where-clauses. The alternative — expressing the value generic only
at method-level, e.g. `where Base == Buffer<Element>.Linked<n>` — causes the
compiler to add an implicit `Base: Copyable` constraint that breaks
`~Copyable` support, because method-level generic constraints are resolved
at a different phase than type-level generics.

The `.Typed<Element>.Valued<n>` chain pays a small verbosity cost (one extra
`Valued<n>` in every accessor type) in exchange for compile-time constraint
composition that works uniformly for `Copyable` and `~Copyable` containers.
The recommended tag-enum-`View` typealias pattern localises this verbosity
to a single declaration per accessor; see the "Value-Generic Verbosity and
the Tag-Enum-View Pattern" article in the `Property_Primitives` umbrella
catalog for the full trade-off analysis and canonical pattern.

For two value generics (e.g. `Buffer<Element>.Linked<N>.Inline<capacity>`),
chain a second suffix into ``Property/View-swift.struct/Typed/Valued/Valued``.

## Topics

### Construction

- ``Property/View-swift.struct/Typed/Valued/init(_:)``

### Access

- ``Property/View-swift.struct/Typed/Valued/base``

## Research

- [Property.View .Valued.Valued Verbosity](../../../Research/property-view-valued-verbosity.md) — Full trade-off analysis of `.Valued.Valued` chain (13 variants considered). Status: RECOMMENDATION.

## Experiments

- [valued-verbosity-best-of-all-worlds](../../../Experiments/valued-verbosity-best-of-all-worlds/) — 13 variants validating approaches to reduce `.Valued.Valued` verbosity. V10 (tag-enum-`View`) is the shipped canonical pattern, applied across 333 tests in buffer-primitives. Status: SUPERSEDED (pattern shipped).
- [view-typed-overload-coexistence](../../../Experiments/view-typed-overload-coexistence/) — Validates `.Valued<N>.Valued<m>` composes correctly. Status: SUPERSEDED (pattern shipped).

## See Also

- ``Property/View-swift.struct/Typed``
- ``Property/View-swift.struct/Typed/Valued/Valued``
