# ``Property_Primitives/Property/Borrow/Typed``

@Metadata {
    @DisplayName("Property.Borrow.Typed")
    @TitleHeading("Swift Primitives")
}

A read-only accessor on a `~Copyable` base with an `Element` parameter.

## Overview

`Property<Tag, Base>.Borrow.Typed<Element>` is the read-only counterpart
of `Property.Inout.Typed` (in `Property Inout Primitives`). The init
takes a borrowing base, so non-mutating `_read` accessors and `borrowing`
functions are valid construction sites; `let`-bound `~Copyable` containers
are valid call sites.

## Example

Adopt the library type via a foundational typealias on the container, pair the
phantom tag with its accessor in its own extension, and declare the namespace's
typed properties on `Property.Borrow.Typed` at module scope:

```swift
extension Container where Element: ~Copyable {
    typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
}

extension Container where Element: ~Copyable {
    enum Peek {}

    var peek: Property<Peek>.Borrow.Typed<Element> {
        _read {
            yield Property<Peek>.Borrow.Typed(self)
        }
    }
}

extension Property.Borrow.Typed
where Tag == Container<Element>.Peek, Base == Container<Element>,
      Element: ~Copyable
{
    var count: Int { base.value.storage.count }
}

let size = container.peek.count      // works on `let`-bound ~Copyable containers
```

## Rationale

`Property.Borrow.Typed` covers the read-only case of the
`Element`-in-scope requirement: `var` extensions on the read-only accessor
cannot introduce their own generic parameters, so `Element` must appear in
the accessor type's generic signature.

The borrowing-init preserves the `let`-bound-callable property that makes
`Borrow` suitable for non-mutating use. This is what distinguishes the
Borrow family from the mutable Inout family: mutable `.Typed` requires
`&self`, which is not available in `_read` accessors or on `let` bindings.

Switch to `Property.Inout.Typed` (in `Property Inout Primitives`) when
extensions need mutation. For a value generic alongside `Element`, see
``Property/Borrow/Typed/Valued``.

## Topics

### Access

- ``Property/Borrow/Typed/base``

## See Also

- ``Property/Borrow``
- ``Property/Borrow/Typed/Valued``
