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
| `Copyable` | Single accessor supports borrow AND consume | ``Property/Consume`` |
| `~Copyable` | Exclusive mutable access | ``Property/Inout-swift.struct`` |
| `~Copyable` | Mutable + `Element` in scope | ``Property/Inout-swift.struct/Typed`` |
| `~Copyable` | Read-only access (including `let` bindings) | ``Property/Borrow`` |
| `~Copyable` | Read-only + `Element` in scope | ``Property/Borrow/Typed`` |
| Has one value generic (`capacity`, `N`) | Append `.Valued<n>` | `…Inout.Typed<E>.Valued<n>` |
| Has two value generics | Append `.Valued<n>.Valued<m>` | `…Inout.Typed<E>.Valued<n>.Valued<m>` |

## The two axes

### Axis 1 — ownership mode

`Copyable` base types can transfer their base by value through a `Property`
proxy (the CoW-safe five-step `_modify` recipe). The storage lives in the
proxy's `_base` field; the accessor transfers the base in and out on scope
entry / exit.

`~Copyable` base types cannot use by-value transfer — ownership is linear. The
`Inout` and `Borrow` variants replace by-value transfer with a tagged
`Ownership.Inout<Base>` (mutable) or `Ownership.Borrow<Base>` (read-only).
The accessor yields a wrapper bound to the borrow of `self`; extensions
read or mutate through `base.value`.

Mapping between the two worlds preserves naming:

| Copyable world | ~Copyable world |
|----------------|-----------------|
| ``Property`` | ``Property/Inout-swift.struct`` |
| ``Property/Typed`` | ``Property/Inout-swift.struct/Typed`` |
| — | ``Property/Borrow`` (no Copyable counterpart — `let` bindings on Copyable use the owned path) |
| — | ``Property/Borrow/Typed`` |

### Axis 2 — extension shape

Swift methods can introduce their own generic parameters (`func back<E>(...)`
compiles on plain ``Property``). Swift `var` properties cannot. If your
extensions are all methods, plain ``Property`` (or ``Property/Inout-swift.struct``
in the ~Copyable world) suffices. If your extensions return `Element?` or
otherwise bind `Element` in their signature, use the `.Typed` variant
(``Property/Typed`` or ``Property/Inout-swift.struct/Typed``) which carries
`Element` in its generic signature.

Rule of thumb: **methods go in ``Property`` / ``Property/Inout-swift.struct``;
properties go in `.Typed` variants.**

## Special cases

### Dual-call-site accessors (borrow and consume from one accessor)

Use ``Property/Consume`` when a single accessor must support both
`container.forEach { }` (borrow) and `container.forEach.consuming { }`
(consume). The caller picks by which method they invoke. Requires
`Base: Copyable`; for `~Copyable` base types the equivalent pattern is a
`.consuming()` namespace method on ``Property/Inout-swift.struct``.

### `let`-bound `~Copyable` bases at the call site

Use ``Property/Borrow``. Its `init(_ base: borrowing Base)` obtains an
`Ownership.Borrow<Base>` from a non-mutating `_read` accessor, which is
reachable from `let` bindings. The mutable
``Property/Inout-swift.struct`` is not — it requires `&self`, which `let`
bindings cannot provide.

### Non-mutating contexts (`Sequence.makeIterator()`, subscript getters)

Use the static ``Property/pointer(to:_:)`` helpers on a stored property.
The closure pattern takes `borrowing` parameters and does not require
`&self`. For reading through a stored property in a `borrowing func`, this
is the escape hatch — parked on `Property` because `Inout` itself requires
`&self` and is structurally unreachable in this context.

### Base types with value generics

Append `.Valued<n>` for each compile-time integer parameter. One value
generic: ``Property/Inout-swift.struct/Typed/Valued``. Two value generics:
``Property/Inout-swift.struct/Typed/Valued/Valued``. The read-only counterparts
go through ``Property/Borrow/Typed/Valued``.

For value-generic containers, the verbose chain should be localised via the
tag-enum-`Accessor` typealias pattern. See
<doc:Value-Generic-Verbosity-And-The-Tag-Enum-Accessor-Pattern> for the canonical
pattern.

## What Property is NOT for

`Property` is not a wrapper for values that carry identity — a `UserID`, an
`OrderID`, a `Graph` index. Those are domain-identity wrappers; use `Tagged`
from `swift-tagged-primitives`. See <doc:Phantom-Tag-Semantics> for the
distinction between the two primitives.

## See Also

- ``Property``
- ``Property/Typed``
- ``Property/Consume``
- ``Property/Inout-swift.struct``
- ``Property/Inout-swift.struct/Typed``
- ``Property/Borrow``
- <doc:GettingStarted>
- <doc:CoW-Safe-Mutation-Recipe>
- <doc:Phantom-Tag-Semantics>
- <doc:~Copyable-Base-Patterns>
- <doc:Value-Generic-Verbosity-And-The-Tag-Enum-Accessor-Pattern>
