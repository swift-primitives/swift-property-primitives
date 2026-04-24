# ``Property_Primitives/Property/View-swift.struct``

@Metadata {
    @DisplayName("Property.View")
    @TitleHeading("Swift Primitives")
}

A view property for `~Copyable` types supporting borrowing and consuming
access.

## Overview

`Property<Tag, Base>.View` wraps an `UnsafeMutablePointer<Base>` and enables
the same fluent accessor syntax used for `Copyable` containers. Mutating
`_read` and `_modify` accessors yield the view so extensions can read
(`func`) or clear through the pointer (`mutating func`) without ownership
transfer.

From non-mutating contexts (`Sequence.makeIterator()`, subscript getters),
reach for the static ``Property/pointer(to:_:)`` helpers — they're the
escape hatch *from* `View`'s `&self` requirement, parked on `Property`
as a sibling of the View family. For View-style read-only fluent access,
use `Property.View.Read` (in `Property View Read Primitives`) instead.

## Example

From a `mutating _read` / `_modify` on a `~Copyable` container:

```swift
extension Buffer where Element: ~Copyable {
    typealias Property<Tag> = Property_Primitives.Property<Tag, Self>

    enum Insert {}

    var insert: Property<Insert>.View {
        mutating _read {
            yield unsafe Property<Insert>.View(&self)
        }
        mutating _modify {
            var view = unsafe Property<Insert>.View(&self)
            yield &view
        }
    }
}

extension Property_Primitives.Property.View
where Tag == Buffer<Element>.Insert, Base == Buffer<Element>,
      Element: ~Copyable
{
    mutating func front(_ element: consuming Element) {
        unsafe base.pointee.push(front: element)
    }
}

buffer.insert.front(element)
```

## Rationale

`~Copyable` containers cannot use the `Copyable`-world pattern of
``Property`` directly: the five-step CoW-safe `_modify` recipe transfers the
base by value, which requires copy semantics. `Property.View` replaces the
by-value transfer with an `UnsafeMutablePointer` — the mutating `_read` /
`_modify` accessors yield the view, and extensions access the base through
`base.pointee`.

Two construction paths exist:

- `init(_ base: UnsafeMutablePointer<Base>)` — the primary path, used in
  `mutating _read` / `_modify` accessors where `&self` is available.
- `init(_ base: borrowing Base)` — marked `@unsafe` because it casts away
  `const` via `UnsafeMutablePointer(mutating:)`. Used in specialized
  contexts (`deinit`, custom transfer sites) where the caller can guarantee
  that mutation through the pointer is valid.

The static ``Property/pointer(to:_:)`` helpers exist for the other side
of the asymmetry: where a non-mutating context needs pointer access to a
stored property, the closure pattern takes `borrowing` parameters and
bypasses the `&self` requirement. This supports `Sequence.makeIterator()`
and subscript-getter call sites that cannot be mutating. The helpers live
on `Property` — not on `View` — because reaching for `View` in a
non-mutating context would be self-contradicting: `View`'s inits require
`&self`. The helpers are a peer of the View machinery, not a member.

For the `~Escapable` history that motivated the mutable-View / read-only-View
split, see the `Property.View.Read` article in `Property View Read
Primitives` and the `property-view-escapable-removal.md` research
document linked there.

## Topics

### Access

- ``Property/View-swift.struct/base``

### Variants

- ``Property/View-swift.struct/Typed``
- ``Property/View-swift.struct/Typed/Valued``
- ``Property/View-swift.struct/Typed/Valued/Valued``

## See Also

- ``Property``
- ``Property/pointer(to:_:)``
- ``Property/pointer(to:mutating:)``
- ``Property/View-swift.struct/Typed``
