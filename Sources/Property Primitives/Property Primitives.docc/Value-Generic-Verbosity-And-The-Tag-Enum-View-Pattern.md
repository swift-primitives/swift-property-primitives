# Value-Generic Verbosity and the Tag-Enum-View Pattern

@Metadata {
    @TitleHeading("Swift Primitives")
}

Value-generic `~Copyable` containers pay a verbosity cost at accessor sites:
the full accessor type is
`Property<Tag, Base>.View.Typed<Element>.Valued<N>.Valued<M>`. This article
explains why each piece is load-bearing, and documents the canonical
tag-enum-`View` typealias pattern that reduces the verbosity to
`Insert.View`.

## Why the chain exists

### Value generics at the type level

When a `~Copyable` container carries a compile-time integer
(`Array.Inline<capacity>`, `Buffer.Linked<N>`), extension where-clauses must
be able to bind that integer. There are two places a where-clause can live:

- **Method-level** — on an individual extension method.
- **Type-level** — on the generic parameters of the extending type.

Only type-level works for `~Copyable` bases. Method-level where-clauses that
mention `Base == Container<n>` cause the compiler to add an implicit
`Base: Copyable` requirement, which breaks `~Copyable` support. `Valued<n>`
lifts the value generic to the type level where it can be bound cleanly:

```swift
// Method-level — adds implicit Base: Copyable. BREAKS for ~Copyable bases.
extension Property.View.Typed {
    mutating func front<let n: Int>(_ element: consuming Element)
    where Base == Buffer<Element>.Linked<n>, Element: ~Copyable { ... }
}

// Type-level via .Valued<n>. WORKS for ~Copyable bases.
extension Property.View.Typed.Valued
where Tag == Buffer<Element>.Linked<n>.Insert,
      Base == Buffer<Element>.Linked<n>,
      Element: ~Copyable {
    mutating func front(_ element: consuming Element) { ... }
}
```

### Two value generics chain

A container with two value generics — e.g.,
`Buffer<Element>.Linked<N>.Inline<capacity>` — needs two suffixes. The chain
``Property/View-swift.struct/Typed/Valued/Valued`` preserves positional
meaning: the first `n` binds the first generic, the second `m` binds the
second.

Three value generics would chain as `.Valued<n>.Valued<m>.Valued<k>`, but
no current consumer uses three. The position is left open pending demand.

## The verbosity problem

The chain accumulates. A container with two value generics produces accessor
types like:

```swift
Property<Buffer<Element>.Linked<N>.Insert, Buffer<Element>.Linked<N>.Inline<capacity>>
    .View.Typed<Element>.Valued<N>.Valued<capacity>
```

That's one accessor signature. The accessor's body typically repeats the same
chain twice more (once in each of `_read` and `_modify`). A container with
five verbs ships five of these — fifteen repetitions per file.

## The canonical pattern: tag enum carries its View

The verbose chain is written exactly once — as a `View` typealias on the tag
enum. Every accessor site reads as `Insert.View`, `Remove.View`, etc.

### One value generic

```swift
extension Buffer.Linked where Element: ~Copyable {
    public enum Insert {
        public typealias View = Property<Insert, Buffer<Element>.Linked<N>>
            .View.Typed<Element>.Valued<N>
    }

    public enum Remove {
        public typealias View = Property<Remove, Buffer<Element>.Linked<N>>
            .View.Typed<Element>.Valued<N>
    }

    public var insert: Insert.View {
        mutating _read  { yield unsafe .init(&self) }
        mutating _modify {
            var view: Insert.View = unsafe .init(&self)
            yield &view
        }
    }

    public var remove: Remove.View {
        mutating _read  { yield unsafe .init(&self) }
        mutating _modify {
            var view: Remove.View = unsafe .init(&self)
            yield &view
        }
    }
}
```

### Two value generics (child type reusing parent's tag)

When a child type (`Buffer.Linked.Inline`) reuses a parent's tag
(`Buffer.Linked.Insert`), define a *local* tag enum on the child that carries
the View typealias for the child's specific Property type:

```swift
extension Buffer.Linked.Inline where Element: ~Copyable {
    public enum Insert {
        public typealias View = Property<Buffer<Element>.Linked<N>.Insert,
                                         Buffer<Element>.Linked<N>.Inline<capacity>>
            .View.Typed<Element>.Valued<N>.Valued<capacity>
    }

    public var insert: Insert.View {
        mutating _read  { yield unsafe .init(&self) }
        mutating _modify {
            var view: Insert.View = unsafe .init(&self)
            yield &view
        }
    }
}
```

The local `Buffer.Linked.Inline.Insert` is a distinct enum from
`Buffer.Linked.Insert`. The tag *used in the Property type* is still the
parent's (`Buffer.Linked.Insert`); the local enum exists only to own the
View typealias. The reader who looks up `Insert.View` sees the full chain
once, at the tag's definition site.

## Why this pattern over alternatives

Thirteen alternatives were validated in the
`valued-verbosity-best-of-all-worlds` experiment. The canonical pattern is V10
(tag-enum-View). Compared to the common alternatives:

| Approach | Accessor verbosity | Discoverability | Extension verbosity | Works today |
|----------|---------------------|-----------------|---------------------|:-----------:|
| Status quo (no alias) | Long | N/A | Long | ✓ |
| Typealias on container (`Prop<Tag>`) | Shorter prefix only; chain remains | Low (name is arbitrary) | Unchanged | ✓ |
| Single typealias (`FullView<Tag>`) | Short | Low (name is arbitrary) | Unchanged | ✓ |
| **Tag-enum `View`** | **`Insert.View`** | **High (tag is self-evident)** | **Unchanged** | **✓** |
| Variadic value generics | Excellent (if it existed) | N/A | Excellent | ✗ (future SE-0452 direction) |
| Macro-generated | Excellent | N/A | Moderate | ✗ (tier-0 packages cannot depend on macro packages) |

The tag-enum-View pattern wins on discoverability: the reader who wants to
know what `Insert.View` expands to looks at `Insert` — the same place they
already look to understand what the tag means.

## What the pattern does NOT solve

Extension declarations remain verbose. The `extension Property.View.Typed.Valued
where Tag == ..., Base == ..., Element: ~Copyable` header cannot be shortened
by any viable option today — it must bind `Tag`, `Base`, and `Element` with
specific types that include value generics. The alternatives that reduce
extension verbosity (variadic value generics, macros, protocol-based
extensions) either don't exist in Swift yet or violate other constraints
(tier-0 dependency rules, naming conventions).

Extensions are written once per namespace per type and read infrequently. The
canonical pattern minimises verbosity where it matters most — the accessor
site, which is read and written at every namespace addition.

## When to apply it

Any `~Copyable` container with a value generic should use the pattern.
Production validation: buffer-primitives ships three files using V10 across
333 tests — the pattern is stable and well-worn.

Copyable containers with value generics (`Array.Static<capacity>` on Copyable
elements, for example) don't need the pattern as urgently because their
accessor types go through ``Property`` rather than the View chain. A typealias
on the container (`typealias Property<Tag> = Property_Primitives.Property<Tag, Self>`)
is sufficient there.

## See Also

- ``Property/View-swift.struct/Typed/Valued``
- ``Property/View-swift.struct/Typed/Valued/Valued``
- ``Property/View-swift.struct/Read/Typed/Valued``
- <doc:Choosing-A-Property-Variant>
- <doc:~Copyable-Base-Patterns>
- [Property.View .Valued.Valued Verbosity](../../../Research/property-view-valued-verbosity.md) — 13-variant trade-off analysis; V10 is the canonical pattern. Status: RECOMMENDATION (DECISION).
