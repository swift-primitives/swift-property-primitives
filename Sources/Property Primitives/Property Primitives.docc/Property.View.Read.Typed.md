# ``Property_Primitives/Property/View-swift.struct/Read/Typed``

@Metadata {
    @DisplayName("Property.View.Read.Typed")
    @TitleHeading("Swift Primitives")
}

A read-only view on a `~Copyable` base with an `Element` parameter.

## Overview

`Property<Tag, Base>.View.Read.Typed<Element>` is the read-only counterpart
of `Property.View.Typed` (in `Property View Primitives`). The borrowing-init
overload works from non-mutating `_read` accessors and `borrowing`
functions, so `let`-bound `~Copyable` containers are valid call sites.

## Example

Adopt the library type via a foundational typealias on the container, pair the
phantom tag with its accessor in its own extension, and declare the namespace's
typed properties on `Property.View.Read.Typed` at module scope:

```swift
extension Container where Element: ~Copyable {
    typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
}

extension Container where Element: ~Copyable {
    enum Peek {}

    var peek: Property<Peek>.View.Read.Typed<Element> {
        _read {
            yield unsafe Property<Peek>.View.Read.Typed(self)
        }
    }
}

extension Property.View.Read.Typed
where Tag == Container<Element>.Peek, Base == Container<Element>,
      Element: ~Copyable
{
    var count: Int { unsafe base.pointee.storage.count }
}

let size = container.peek.count      // works on `let`-bound ~Copyable containers
```

## Rationale

`Property.View.Read.Typed` covers the read-only case of the
`Element`-in-scope requirement: `var` extensions on the read-only view
cannot introduce their own generic parameters, so `Element` must appear in
the view type's generic signature.

The borrowing-init overload preserves the `let`-bound-callable property
that makes `Read` suitable for non-mutating use. This is what distinguishes
the Read family from the mutable View family: mutable `.Typed` requires
`&self`, which is not available in `_read` accessors or on `let` bindings.

Switch to `Property.View.Typed` (in `Property View Primitives`) when
extensions need mutation. For a value generic alongside `Element`, see
``Property/View-swift.struct/Read/Typed/Valued``.

## Topics

### Access

- ``Property/View-swift.struct/Read/Typed/base``

## See Also

- ``Property/View-swift.struct/Read``
- ``Property/View-swift.struct/Read/Typed/Valued``
