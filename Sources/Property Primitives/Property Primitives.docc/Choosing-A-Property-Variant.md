# Choosing a Property Variant

@Metadata {
    @TitleHeading("Swift Primitives")
}

Pick the `Property` variant by two questions — is your `Base` `Copyable` or
`~Copyable`?, and do your extensions need an `Element` type parameter in scope
for `var` properties?

## Decision matrix

| Base is… | Extension shape | Use |
|---------------|-----------------|-----|
| `Copyable` | Methods only (`func back<E>(...)`) | ``Property`` |
| `Copyable` | Properties needing `Element` (`var back: E?`) | ``Property/Typed`` |
| `Copyable` | Single accessor supports borrow AND consume | ``Property/Consuming`` |
| `~Copyable` | Mutable pointer access | ``Property/View-swift.struct`` |
| `~Copyable` | Mutable + `Element` in scope | ``Property/View-swift.struct/Typed`` |
| `~Copyable` | Read-only access (including `let` bindings) | ``Property/View-swift.struct/Read`` |
| `~Copyable` | Read-only + `Element` in scope | ``Property/View-swift.struct/Read/Typed`` |
| Has one value generic (`capacity`, `N`) | Append `.Valued<n>` | `…View.Typed<E>.Valued<n>` |
| Has two value generics | Append `.Valued<n>.Valued<m>` | `…View.Typed<E>.Valued<n>.Valued<m>` |

## The two axes

### Axis 1 — ownership mode

`Copyable` base types can transfer their base by value through a `Property`
proxy (the CoW-safe five-step `_modify` recipe). The storage lives in the
proxy's `_base` field; the accessor transfers the base in and out on scope
entry / exit.

`~Copyable` base types cannot use by-value transfer — ownership is linear. The
View family replaces by-value transfer with `UnsafeMutablePointer<Base>` (or
`UnsafePointer<Base>` for read-only). The accessor yields the view wrapping a
pointer to `self`; extensions read or mutate through the pointer.

Mapping between the two worlds preserves naming:

| Copyable world | ~Copyable world |
|----------------|-----------------|
| ``Property`` | ``Property/View-swift.struct`` |
| ``Property/Typed`` | ``Property/View-swift.struct/Typed`` |
| — | ``Property/View-swift.struct/Read`` (no Copyable counterpart — `let` bindings on Copyable use the owned path) |
| — | ``Property/View-swift.struct/Read/Typed`` |

### Axis 2 — extension shape

Swift methods can introduce their own generic parameters (`func back<E>(...)`
compiles on plain ``Property``). Swift `var` properties cannot. If your
extensions are all methods, plain ``Property`` (or ``Property/View-swift.struct``
in the ~Copyable world) suffices. If your extensions return `Element?` or
otherwise bind `Element` in their signature, use the `.Typed` variant
(``Property/Typed`` or ``Property/View-swift.struct/Typed``) which carries
`Element` in its generic signature.

Rule of thumb: **methods go in ``Property`` / ``Property/View-swift.struct``;
properties go in `.Typed` variants.**

## Special cases

### Dual-call-site accessors (borrow and consume from one accessor)

Use ``Property/Consuming`` when a single accessor must support both
`container.forEach { }` (borrow) and `container.forEach.consuming { }`
(consume). The caller picks by which method they invoke. Requires
`Base: Copyable`; for `~Copyable` base types the equivalent pattern is a
`.consuming()` namespace method on ``Property/View-swift.struct``.

### `let`-bound `~Copyable` bases at the call site

Use ``Property/View-swift.struct/Read``. The borrowing-init overload
(`init(_ base: borrowing Base)`) obtains an `UnsafePointer` from a non-mutating
`_read` accessor, which is reachable from `let` bindings. The mutable
``Property/View-swift.struct`` is not — it requires `&self`, which `let`
bindings cannot provide.

### Non-mutating contexts (`Sequence.makeIterator()`, subscript getters)

Use the static ``Property/View-swift.struct/pointer(to:_:)`` helpers on a
stored property. The closure pattern takes `borrowing` parameters and does not
require `&self`. For reading through a stored property in a `borrowing func`,
this is the escape hatch.

### Base types with value generics

Append `.Valued<n>` for each compile-time integer parameter. One value
generic: ``Property/View-swift.struct/Typed/Valued``. Two value generics:
``Property/View-swift.struct/Typed/Valued/Valued``. The read-only counterparts
go through ``Property/View-swift.struct/Read/Typed/Valued``.

For value-generic containers, the verbose chain should be localised via the
tag-enum-`View` typealias pattern. See
<doc:Value-Generic-Verbosity-And-The-Tag-Enum-View-Pattern> for the canonical
pattern.

## What Property is NOT for

`Property` is not a wrapper for values that carry identity — a `UserID`, an
`OrderID`, a `Graph` index. Those are domain-identity wrappers; use `Tagged`
from `swift-tagged-primitives`. See <doc:Phantom-Tag-Semantics> for the
distinction between the two primitives.

## See Also

- ``Property``
- ``Property/Typed``
- ``Property/Consuming``
- ``Property/View-swift.struct``
- ``Property/View-swift.struct/Typed``
- ``Property/View-swift.struct/Read``
- <doc:GettingStarted>
- <doc:CoW-Safe-Mutation-Recipe>
- <doc:Phantom-Tag-Semantics>
- <doc:~Copyable-Base-Patterns>
- <doc:Value-Generic-Verbosity-And-The-Tag-Enum-View-Pattern>
