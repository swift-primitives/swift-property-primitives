# ``Property_Primitives/Property``

@Metadata {
    @DisplayName("Property")
    @TitleHeading("Swift Primitives")
}

An owned property for CoW-safe mutation namespacing.

## Overview

`Property<Tag, Base>` wraps a base value for fluent accessor namespaces. The
phantom `Tag` discriminates which extensions apply, so one container can expose
multiple namespaces (`push`, `pop`, `peek`) each with its own extension surface.

`Property` is the anchor of the type family. Four variants extend it along
orthogonal axes: `Property.Typed` (in `Property Typed Primitives`) adds an
`Element` type parameter so `var` extensions can bind to it;
`Property.Consuming` (in `Property Consuming Primitives`) adds the
borrow-vs-consume state machine; `Property.View` (in `Property View
Primitives`) adds `UnsafeMutablePointer`-based access for `~Copyable`
containers; `Property.View.Read` (in `Property View Read Primitives`) adds
read-only pointer access. Navigate to those variants through the
`Property_Primitives` umbrella catalog.

## Example

Define a tag, a typealias, an accessor, and a method extension. The accessor
uses the five-step CoW-safe `_modify` recipe to transfer the base through the
property proxy.

```swift
extension Stack where Element: Copyable {
    enum Push {}
    typealias Property<Tag> = Property_Primitives.Property<Tag, Stack<Element>>

    var push: Property<Push> {
        _read { yield Property<Push>(self) }
        _modify {
            makeUnique()                   // 1. Uniqueness before transfer
            reserve(count + 1)             // 2. Pre-allocate
            var property: Property<Push> = .init(self)
            self = Stack()                 // 3. Clear self
            defer { self = property.base } // 4. Restore on exit
            yield &property                // 5. Yield
        }
    }
}

extension Property_Primitives.Property {
    mutating func back<E>(_ element: E)
    where Tag == Stack<E>.Push, Base == Stack<E> {
        base.append(element)
    }
}

stack.push.back(element)
```

## Rationale

Before `Property`, each accessor namespace required a bespoke proxy struct:
one per verb per container, each with its own storage, init, `.base` accessor,
and conditional `Sendable` / `Copyable` conformances. Five verbs on a stack
meant five structs. The mechanical boilerplate hid the distinction between
verbs; the vocabulary proliferated without earning its keep.

`Property<Tag, Base>` collapses the boilerplate into one type. The `Tag`
parameter is a phantom — it carries no runtime state and exists only to
discriminate between extension sets. Five verbs on a stack now mean five empty
enums (`enum Push {}`) and five extensions on `Property` with
`where Tag == Stack<E>.Push` clauses. The storage, the init, the `.base`
accessor, and the conditional conformances are provided by `Property` itself
once.

The parameter order — `Property<Tag, Base>`, discriminator first, value
second — mirrors the ecosystem's `Tagged<Tag, RawValue>`. Tag-first reads as
"property of kind X" at the common site `Property<Push, Stack<Element>>`,
rather than "Stack's property of kind Push". The Tag-first shape also
composes naturally with a `typealias Property<Tag>` scoped to the container,
which eliminates `Base` repetition at every accessor declaration.

## Topics

### Construction

- ``Property/init(_:)``

### Access

- ``Property/base``

## Research

- [Property Type Family](../../../Research/property-type-family.md) — Flagship paper: three-category accessor taxonomy, phantom type pattern, protocol-conformance investigation. Status: DECISION.
- [Protocol Conformance and Phantom Type Generalization](../../../Research/problem-protocol-conformance-and-phantom-type-generalization.md) — Why `Property` cannot easily carry protocol conformances; motivates the sibling variants. Status: ANALYSIS.
- [Variant Decomposition Rationale](../../../Research/variant-decomposition-rationale.md) — Why five targets along the ownership / access-model axis. Status: DECISION.

## Experiments

- [property-generic-property-test](../../../Experiments/property-generic-property-test/) — Validates the `typealias Property<Tag>` shorthand eliminates redundant `Element` repetition at call sites. Status: CONFIRMED.

## See Also

The variant types (`Property.Typed`, `Property.Consuming`, `Property.View`,
`Property.View.Read`) and cross-symbol pattern guides live in the
`Property_Primitives` umbrella catalog.
