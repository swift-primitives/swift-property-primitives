# ``Property_Primitives/Property/Consuming``

@Metadata {
    @DisplayName("Property.Consuming")
    @TitleHeading("Swift Primitives")
}

A property that supports both borrowing and consuming access from a single
accessor.

## Overview

`Property<Tag, Base>.Consuming<Element>` enables a single accessor to support
call sites like `container.forEach { }` (borrow) AND
`container.forEach.consuming { }` (consume). The choice is made by *which*
method the caller invokes — a `callAsFunction(_:)` for borrow, a
`mutating consuming(_:)` for consume. Consumption is tracked in a
reference-type ``Property/Consuming/State``; the `_modify` accessor's
`defer` block queries the state via
``Property/Consuming/restore()`` to decide whether to restore `self`.

Requires `Base: Copyable`. For `~Copyable` containers, use
`Property.View` (in `Property View Primitives`) with the `.consuming()`
namespace-method pattern.

## Example

Adopt the library type via a foundational typealias on the container, pair the
phantom tag with its accessor in its own extension, and declare the namespace's
methods on `Property.Consuming` at module scope:

```swift
extension Container {
    typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
}

extension Container {
    enum ForEach {}

    var forEach: Property<ForEach>.Consuming<Element> {
        _read { yield Property<ForEach>.Consuming(self) }
        mutating _modify {
            var property = Property<ForEach>.Consuming(self)
            self = Container()
            defer {
                if let restored = property.restore() {
                    self = restored
                }
            }
            yield &property
        }
    }
}

extension Property.Consuming
where Tag == Container<Element>.ForEach, Base == Container<Element> {
    func callAsFunction(_ body: (Element) -> Void) {
        guard let base = borrow() else { return }
        for element in base.elements { body(element) }
    }

    mutating func consuming(_ body: (Element) -> Void) {
        guard let base = consume() else { return }
        for element in base.elements { body(element) }
    }
}

container.forEach { print($0) }             // borrow — container preserved
container.forEach.consuming { process($0) } // consume — container emptied
```

## Rationale

The dual-call-site idiom — `.forEach { }` vs. `.forEach.consuming { }` —
surfaced during the ecosystem's iteration primitives design. Both forms
should read naturally from a single accessor: the borrow form is the default
(most callers don't want to empty the container), the consuming form is an
opt-in (for callers handing the elements onward, e.g. transferring to another
data structure).

`Property.Consuming` makes this work without requiring two accessors. The
`_modify` body transfers `self` to the property's `State`, then on scope exit
checks `restore()`: if the consuming path was taken, the container stays
empty; if not, the container is restored. The caller's choice of method
(`callAsFunction` vs. `consuming`) is what drives the state transition —
the accessor and `_modify` body are identical for both call sites.

The state is a reference type by necessity. The `mutating func consuming()`
needs to set a flag that the outer `defer` block can observe *after* the
method returns. Value-type state wouldn't carry the mutation across the
yield/defer boundary — the `defer` block would see the pre-mutation value
and unconditionally restore, undoing the consume.

The type requires `Base: Copyable` because the `_modify` recipe transfers
the base by value (`self = Container()` clears the caller's storage; the
restore path assigns `property.state.borrow()` back). `~Copyable` containers
use `Property.View` (in `Property View Primitives`) with a `.consuming()`
namespace-method pattern instead — pointer-based access avoids the
by-value transfer.

## Topics

### Construction

- ``Property/Consuming/init(_:)``
- ``Property/Consuming/init(state:)``

### Access

- ``Property/Consuming/borrow()``
- ``Property/Consuming/consume()``
- ``Property/Consuming/restore()``

### State

- ``Property/Consuming/state``
- ``Property/Consuming/isConsumed``
- ``Property/Consuming/State``

## See Also

- ``Property/Consuming/State``
- ``Property``
