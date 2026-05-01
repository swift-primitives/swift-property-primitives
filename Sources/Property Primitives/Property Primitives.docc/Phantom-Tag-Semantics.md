# Phantom Tag Semantics

@Metadata {
    @TitleHeading("Swift Primitives")
}

``Property`` and `Tagged` (from `swift-tagged-primitives`) are structurally
isomorphic: each is a single-field wrapper parameterized by a phantom `Tag`
and a value type. They look the same. They do different jobs. Understanding
the difference is how you pick the right primitive.

## Structural equivalence

```swift
// swift-tagged-primitives
public struct Tagged<Tag: ~Copyable, RawValue: ~Copyable>: ~Copyable {
    public var rawValue: RawValue
}

// swift-property-primitives
public struct Property<Tag, Base: ~Copyable>: ~Copyable {
    @usableFromInline internal var _base: Base
}
extension Property where Base: ~Copyable {
    public var base: Base { _read { yield _base } _modify { yield &_base } }
}
```

Both wrap a value (`rawValue` / `_base`), both discriminate on a phantom
`Tag`. Parameter order is identical: discriminator first, value second. The
only structural difference is that `Tagged` stores its value in a public
`rawValue` field while `Property` exposes its base through a coroutine
accessor — an implementation-level choice.

So what distinguishes them?

## Semantic roles

The distinction is what the phantom tag *discriminates*.

| | `Tagged` | `Property` |
|---|----------|------------|
| What the tag discriminates | **Domain identity** of the value | **Verb namespace** dispatched via extensions |
| Example | `Index<Graph>` ≠ `Index<Bit>` — different indices in different domains | `Property<Push, Stack>` vs `Property<Pop, Stack>` — same stack, different namespace |
| Tag values typical | Existing domain types (`Graph`, `Bit`, `UserID`) | Empty enums defined per-container (`enum Push {}`) |
| Meaningful ops on tag | `retag<NewTag>` (phantom coercion is meaningful) | None — retagging `Push` to `Pop` would be semantically nonsensical |
| Extension surface | Per-domain API (`extension Tagged where Tag == Ordinal { ... }`) | Per-namespace API (`extension Property where Tag == Stack<E>.Push { mutating func back(...) }`) |

`Tagged` gives values *identity* — the same operations apply; the tag says
what kind of thing the value is. Bring a `rawValue` through without losing
its domain. `retag<NewTag>` is the canonical meaningful operation — it moves
a value from one domain to another explicitly.

`Property` gives values *operations* — the container is the same; the tag
says what you can do with it. `stack.push` and `stack.pop` both wrap the same
`Stack`, differing only in which extensions apply. `retag<NewTag>` makes no
semantic sense — rebranding a Push proxy as a Pop proxy would apply a
different namespace to an operation that was already picked.

## Why two types instead of one

A single `PhantomTagged<Tag, Value, Role>` with a `Role` type parameter has
been considered and rejected. The problem is extension-namespace pollution:

- If `Role` is compile-time only (a phantom), extensions on `PhantomTagged<_, _, VerbNamespace>` still bleed across all `Tagged`-with-that-tag sites, because Swift's extension system cannot constrain extensions on arbitrary type parameters to values of a phantom-role type parameter.
- If `Role` is runtime-represented (an `enum` or marker protocol), the zero-cost guarantee is lost.

Keeping them as separate nominal types preserves extension-namespace
isolation. Extensions on `Property<Push, Stack>` cannot be seen from `Tagged`
consumers; extensions on `Tagged<Ordinal, Int>` cannot be seen from Property
consumers. That isolation is what makes the accessor-namespace pattern work.

Property could in principle compose its storage on top of `Tagged` (the top
struct only — the variants `Property.View`, `.View.Read`, `.Consuming` have
different storage). The gain is marginal — one-fifth of the Property surface
— and the cost is a cross-package dependency plus an extra field-access layer.
The ecosystem has chosen not to pursue composition.

## How to use the tags

### Property tags

- **One empty enum per namespace**, nested on the container.
- **No `*Tag` suffix** — use `Push`, not `PushTag` (per
  `feedback_no_tag_suffix`).
- **No cases, no stored state** — the tag is phantom; it exists only to
  discriminate extensions.

```swift
extension Stack where Element: Copyable {
    public enum Push {}    // ✓
    public enum Pop {}     // ✓
    public enum Peek {}    // ✓
}
```

Anti-patterns:

```swift
public enum StackPush {}      // ❌ Top-level; pollutes consuming-module namespace.
public enum PushTag {}        // ❌ Tag suffix forbidden.
public enum Push { case immediate }  // ❌ Tags are phantom; no cases.
```

### Tagged tags (for contrast)

- **Pre-existing domain types**, not purpose-built empty enums: `Graph`,
  `UserID`, `Bit`, `Ordinal`.
- **`retag<NewTag>` is a real operation** — crossing from `Index<Graph>` to
  `Index<Bit>` is a meaningful explicit coercion.
- **Extensions are per-domain, not per-namespace**.

```swift
// Tagged usage:
typealias UserID = Tagged<User, UInt64>
typealias OrderID = Tagged<Order, UInt64>

extension Tagged where Tag == User {
    var isGuest: Bool { rawValue == 0 }
}
```

## Where the container-scoped `Property<Tag>` typealias applies

Per the Getting Started tutorial and `[PRP-003]`, a container that exposes
Property accessors declares a container-scoped typealias:

```swift
extension Deque where Element: Copyable {
    typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
}
```

That typealias resolves in three kinds of position — and does **not**
resolve in a fourth. Knowing which is which avoids one compiler error that
reads as unrelated to the typealias.

### Works — accessor declarations

Inside the container's own extensions, the short form is the canonical
shape. Use it for every accessor-declaration site.

```swift
extension Deque {
    var push: Property<Push> { /* ... */ }
    var peek: Property<Peek>.Typed<Element> { /* ... */ }
}
```

### Works — nested tag enum's own typealias body

Inside a nested tag enum declared on the container, unqualified
`Property<Tag>` still resolves via enclosing-type lookup:

```swift
extension Ring where Element: ~Copyable {
    typealias Property<Tag> = Property_Primitives.Property<Tag, Self>

    enum Insert {
        typealias View = Property<Insert>.View.Typed<Element>.Valued<N>
    }
}
```

The tag-enum-`View` pattern in production consumers
(`swift-queue-primitives`, `swift-hash-table-primitives`) spells out the
underlying type in long form inside this typealias body — not because the
short form fails to compile, but because those consumers do not define a
container-scoped `Property<Tag>` at all. The long form keeps the tag-enum
typealias self-contained: a reader can copy it into any container without a
prerequisite container-level typealias. Both forms work; the convention is
context-dependent.

### Works — method extension on `Deque.Property`

Method extensions can attach via the container-scoped typealias:

```swift
extension Deque.Property {
    mutating func front<E>(_ element: E)
    where Tag == Deque<E>.Push, Base == Deque<E> {
        base._storage.insert(element, at: 0)
    }
}
```

The where-clause still spells out `Tag == Deque<E>.Push, Base == Deque<E>`
with a method-level generic `E` — the typealias binds `Tag` only, not
`Element`. For generic `Deque<Element>` this matches the canonical
module-qualified form line-for-line. The container-scoped form is
permissible; the ecosystem convention still prefers the module-qualified
form below for consistency with the next case.

### Does not work — extension on a nested type of the typealias

Extending `Property.Typed`, `Property.View`, `Property.Consuming`, etc.
through the container-scoped typealias fails:

```swift
extension Deque.Property.Typed    // ❌ compile error
where Tag == Deque<Element>.Peek, Base == Deque<Element> {
    var last: Element? { base._storage.last }
}
```

The compiler reports:

```
error: 'Typed' is not a member type of type 'Deque.Property'
```

Swift's generic typealias is not expanded during extension member-type
lookup. `Deque.Property<Peek>.Typed<E>` is valid at a **use** site — the
use-site lookup goes through the underlying Property and picks up `Typed`
from there — but an **extension** on `Deque.Property.Typed` walks the
typealias's declaration signature, where `Typed` is not a member.

Use the imported library type at module scope:

```swift
extension Property.Typed    // ✓ — at module scope, Property is the imported library type
where Tag == Deque<Element>.Peek, Base == Deque<Element> {
    var back: Element? { base._storage.last }
    var count: Int { base._storage.count }
}
```

The fully module-qualified form `extension Property_Primitives.Property.Typed`
also works and is equivalent; the unqualified form (above) is the canonical
shape because it relies on the standard `import Property_Primitives` already
needed for the accessor declarations.

### Summary

| Site | Short form? | Canonical form |
|------|:-----------:|----------------|
| Accessor declaration inside container | ✓ | `var push: Property<Push>` |
| Nested tag enum's `typealias View = ...` body | ✓ | Long form by convention (self-containment) |
| Extension on `Property` itself (at module scope) | ✓ | `extension Property where ...` |
| Extension on `Property.Typed` / `.View` / `.Consuming` / ... (at module scope) | ✓ | `extension Property.Typed where ...` |
| Extension via container-scoped typealias path (`Deque.Property.Typed`) | ✗ | Use module-scope form above |

The hard rule: extension lookup does not walk the container's `Property<Tag>`
typealias to its nested `.Typed` / `.View` / `.Consuming`. At module scope,
the imported `Property` is the library type directly, so nested-type
extension lookup works.

Empirical verification: `Experiments/property-typealias-extension-forms/`
in this package. The experiment builds a `Deque` with `push` and `peek`
accessors, demonstrates Shapes A and B succeeding, and confirms the
Shape B' failure by compiler output.

## Decision test

If your tag is a purpose-built empty enum that names an operation (`Push`,
`Peek`, `Insert`, `ForEach`) and you want a distinct set of extensions for
it — you want ``Property``.

If your tag is an existing domain type that names what kind of value you're
wrapping (`UserID`, `Ordinal<Offset>`, `Index<Graph>`) and you want per-domain
operations — you want `Tagged`.

The two are co-abstractions, not competitors. Many primitives consume both.

## See Also

- ``Property``
- <doc:Choosing-A-Property-Variant>
- <doc:GettingStarted>
