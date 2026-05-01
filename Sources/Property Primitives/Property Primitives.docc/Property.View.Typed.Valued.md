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

Adopt the library type via a foundational typealias on the container, declare
the accessor on the container, and declare the namespace's methods on
`Property.View.Typed.Valued` at module scope:

```swift
extension Array.Inline where Element: ~Copyable {
    typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
}

extension Array.Inline where Element: ~Copyable {
    var forEach: Property<Sequence.ForEach>.View.Typed<Element>.Valued<capacity> {
        mutating _read  { yield unsafe .init(&self) }
        mutating _modify {
            var view: Property<Sequence.ForEach>.View.Typed<Element>.Valued<capacity> = unsafe .init(&self)
            yield &view
        }
    }
}

extension Property.View.Typed.Valued
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

## See Also

- ``Property/View-swift.struct/Typed``
- ``Property/View-swift.struct/Typed/Valued/Valued``
