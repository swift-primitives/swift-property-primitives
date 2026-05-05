# ``Property_Primitives/Property/Inout-swift.struct``

@Metadata {
    @DisplayName("Property.Inout")
    @TitleHeading("Swift Primitives")
}

An exclusive mutable accessor for `~Copyable` types.

## Overview

`Property<Tag, Base>.Inout` wraps a `Tagged<Tag, Ownership.Inout<Base>>` —
a phantom-tagged exclusive mutable reference — and enables the same fluent
accessor syntax used for `Copyable` containers. Mutating `_read` and
`_modify` accessors yield the wrapper so extensions can read (`func`) or
mutate (`mutating func`) through `base.value` without ownership transfer.

From non-mutating contexts (`Sequence.makeIterator()`, subscript getters),
reach for the static ``Property/pointer(to:_:)`` helpers — they're the
escape hatch *from* `Inout`'s `&self` requirement, parked on `Property`
as a sibling of the variant family. For read-only fluent access, use
`Property.Borrow` (in `Property Borrow Primitives`) instead.

## Example

Adopt the library type via a foundational typealias on the container, pair the
phantom tag with its accessor in its own extension, and declare the namespace's
methods on `Property.Inout` at module scope:

```swift
extension Buffer where Element: ~Copyable {
    typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
}

extension Buffer where Element: ~Copyable {
    enum Insert {}

    var insert: Property<Insert>.Inout {
        mutating _read {
            yield Property<Insert>.Inout(&self)
        }
        mutating _modify {
            var accessor = Property<Insert>.Inout(&self)
            yield &accessor
        }
    }
}

extension Property.Inout
where Tag == Buffer<Element>.Insert, Base == Buffer<Element>,
      Element: ~Copyable
{
    mutating func front(_ element: consuming Element) {
        base.value.push(front: element)
    }
}

buffer.insert.front(element)
```

## Rationale

`~Copyable` containers cannot use the `Copyable`-world pattern of
``Property`` directly: the five-step CoW-safe `_modify` recipe transfers the
base by value, which requires copy semantics. `Property.Inout` replaces the
by-value transfer with a tagged exclusive borrow — the mutating `_read` /
`_modify` accessors yield the wrapper, and extensions access the base
through `base.value`.

Two construction paths exist:

- `init(_ base: inout Base)` — the canonical path, used in
  `mutating _read` / `_modify` accessors where `&self` is available.
- `init(_ base: borrowing Base)` — marked `@unsafe` because it casts away
  `const` to materialise an `Ownership.Inout`. Used in specialised
  contexts (`deinit`, custom transfer sites) where the caller can guarantee
  that mutation through the accessor is valid.

Access goes through `base.value` — no `unsafe` marker is needed at the call
site; `Ownership.Inout` is `@safe` and the lifetime is compiler-enforced via
`~Escapable`.

The static ``Property/pointer(to:_:)`` helpers exist for the other side
of the asymmetry: where a non-mutating context needs pointer access to a
stored property, the closure pattern takes `borrowing` parameters and
bypasses the `&self` requirement. This supports `Sequence.makeIterator()`
and subscript-getter call sites that cannot be mutating. The helpers live
on `Property` — not on `Inout` — because reaching for `Inout` in a
non-mutating context would be self-contradicting: `Inout`'s safe init
requires `&self`. The helpers are a peer of the Inout machinery, not a
member.

For the read-only counterpart, see the `Property.Borrow` article in
`Property Borrow Primitives`.

## Topics

### Access

- ``Property/Inout-swift.struct/base``

### Variants

- ``Property/Inout-swift.struct/Typed``
- ``Property/Inout-swift.struct/Typed/Valued``
- ``Property/Inout-swift.struct/Typed/Valued/Valued``

## See Also

- ``Property``
- ``Property/pointer(to:_:)``
- ``Property/pointer(to:mutating:)``
- ``Property/Inout-swift.struct/Typed``
