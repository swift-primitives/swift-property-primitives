# ``Property_Primitives/Property/View-swift.struct/Typed``

@Metadata {
    @DisplayName("Property.View.Typed")
    @TitleHeading("Swift Primitives")
}

A mutable view on a `~Copyable` base with an `Element` parameter.

## Overview

`Property<Tag, Base>.View.Typed<Element>` is the `~Copyable` equivalent of
`Property.Typed` (in `Property Typed Primitives`): it combines
``Property/View-swift.struct``'s pointer access with an `Element` type
parameter so `var` extensions can bind to `Element` in a where-clause.

## Example

Adopt the library type via a foundational typealias on the container, pair the
phantom tag with its accessor in its own extension, and declare the namespace's
typed properties on `Property.View.Typed` at module scope:

```swift
extension Container where Element: ~Copyable {
    typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
}

extension Container where Element: ~Copyable {
    enum Access {}

    var access: Property<Access>.View.Typed<Element> {
        mutating _read {
            yield unsafe Property<Access>.View.Typed(&self)
        }
        mutating _modify {
            var view = unsafe Property<Access>.View.Typed<Element>(&self)
            yield &view
        }
    }
}

extension Property.View.Typed
where Tag == Container<Element>.Access, Base == Container<Element>,
      Element: ~Copyable
{
    var count: Int { unsafe base.pointee.count }
}
```

## Rationale

The language asymmetry that motivates `Property.Typed` in the `Copyable`
world applies equally in the `~Copyable` world: property extensions cannot
introduce their own generic parameters, so extensions that return `Element?`
or bind `Element` must have it in the type's generic signature.

`Property.View.Typed<Element>` smuggles `Element` in by parameterizing the
view type itself. Extensions on `Property.View.Typed` write
`where Element: ~Copyable` in the where-clause and access the base through
`base.pointee`. The parameter shape (`Typed<Element>`) mirrors the
`Copyable`-world `Property.Typed` exactly; only the storage mechanism
(`UnsafeMutablePointer` vs. by-value) differs.

When the container also has value generics (`Buffer<Element>.Linked<N>`,
`Array<Element>.Inline<capacity>`), append `.Valued<n>` for each lifted
integer — see ``Property/View-swift.struct/Typed/Valued``.

## Topics

### Construction

- ``Property/View-swift.struct/Typed/init(_:)``

### Access

- ``Property/View-swift.struct/Typed/base``

## See Also

- ``Property/View-swift.struct``
- ``Property/View-swift.struct/Typed/Valued``
