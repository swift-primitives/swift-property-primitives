# ``Property_Primitives/Property/Typed``

@Metadata {
    @DisplayName("Property.Typed")
    @TitleHeading("Swift Primitives")
}

A property with an `Element` parameter for property-case extensions.

## Overview

`Property<Tag, Base>.Typed<Element>` carries `Element` in its generic
signature so `var` extensions can bind to it in a where-clause.

## Example

Adopt the library type via a foundational typealias on the container, pair the
phantom tag with its accessor in its own extension, and declare property-case
extensions on `Property.Typed` at module scope:

```swift
extension Stack {
    typealias Property<Tag> = Property_Primitives.Property<Tag, Stack<Element>>
}

extension Stack {
    enum Peek {}

    var peek: Property<Peek>.Typed<Element> {
        Property<Peek>.Typed(self)
    }
}

extension Property.Typed
where Tag == Stack<Element>.Peek, Base == Stack<Element> {
    var back: Element?  { base.last }
    var front: Element? { base.first }
    var count: Int      { base.count }
}

let last = stack.peek.back
```

## Rationale

Swift methods can introduce their own generic parameters at the call site
(`func back<E>(...)` compiles), but `var` properties cannot. This asymmetry
would force every property-case extension to be written as a method, losing
the natural read-as-property call site (`stack.peek.back` vs.
`stack.peek.back()`).

`Property.Typed<Element>` resolves the asymmetry by carrying `Element` in the
type's generic signature. Extensions on `Property.Typed` see `Element` through
the where-clause, so they can write `var back: Element?` directly. The cost
is a slightly longer accessor type (`Property<Peek>.Typed<Element>` vs.
`Property<Peek>`); the benefit is that property-case extensions read exactly
as properties should.

The `.Typed<Element>` suffix composes with the other variant axes: the
`~Copyable` world has `Property.View.Typed` for the same property-case
shape, and `Property.View.Read.Typed` for read-only. The suffix carries
the same meaning ("Element in scope") across the type family. See those
types in the `Property_Primitives` umbrella catalog.

## Topics

### Construction

- ``Property/Typed/init(_:)``

### Access

- ``Property/Typed/base``

## See Also

- ``Property``
