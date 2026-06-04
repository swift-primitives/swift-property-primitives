# ``Property_Primitives/Property/Inout-swift.struct/Typed``

@Metadata {
    @DisplayName("Property.Inout.Typed")
    @TitleHeading("Swift Primitives")
}

An exclusive mutable accessor on a `~Copyable` base with an `Element` parameter.

## Overview

`Property<Tag, Base>.Inout.Typed<Element>` is the `~Copyable` equivalent of
`Property.Typed` (in `Property Typed Primitives`): it combines
``Property/Inout-swift.struct``'s mutable borrow access with an `Element`
type parameter so `var` extensions can bind to `Element` in a where-clause.

## Example

Adopt the library type via a foundational typealias on the container, pair the
phantom tag with its accessor in its own extension, and declare the namespace's
typed properties on `Property.Inout.Typed` at module scope:

```swift
extension Container where Element: ~Copyable {
    typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
}

extension Container where Element: ~Copyable {
    enum Access {}

    var access: Property<Access>.Inout.Typed<Element> {
        mutating _read {
            yield Property<Access>.Inout.Typed(&self)
        }
        mutating _modify {
            var accessor = Property<Access>.Inout.Typed<Element>(&self)
            yield &accessor
        }
    }
}

extension Property.Inout.Typed
where Tag == Container<Element>.Access, Base == Container<Element>,
      Element: ~Copyable
{
    var count: Int { base.value.count }
}
```

## Rationale

The language asymmetry that motivates `Property.Typed` in the `Copyable`
world applies equally in the `~Copyable` world: property extensions cannot
introduce their own generic parameters, so extensions that return `Element?`
or bind `Element` must have it in the type's generic signature.

`Property.Inout.Typed<Element>` smuggles `Element` in by parameterizing the
accessor type itself. Extensions on `Property.Inout.Typed` write
`where Element: ~Copyable` in the where-clause and access the base through
`base.value`. The parameter shape (`Typed<Element>`) mirrors the
`Copyable`-world `Property.Typed` exactly; only the storage mechanism
(tagged exclusive borrow vs. by-value) differs.

When the container also has value generics (`Buffer<Storage<Element>.Heap>.Linked<N>`,
`Array<Element>.Inline<capacity>`), append `.Valued<n>` for each lifted
integer — see ``Property/Inout-swift.struct/Typed/Valued``.

## Topics

### Construction

- ``Property/Inout-swift.struct/Typed/init(_:)``

### Access

- ``Property/Inout-swift.struct/Typed/base``

## See Also

- ``Property/Inout-swift.struct``
- ``Property/Inout-swift.struct/Typed/Valued``
