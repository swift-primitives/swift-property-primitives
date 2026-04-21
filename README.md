# Property Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-primitives/swift-property-primitives/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-primitives/swift-property-primitives/actions/workflows/ci.yml)

Fluent accessor property primitives: unifies `Tag`-discriminated proxy patterns (`deque.push.back`, `buffer.insert.at`) across the swift-primitives ecosystem with full `~Copyable` support and CoW-safe `_modify` semantics.

## Why & how

Before `Property<Tag, Base>`, every fluent accessor namespace on a container type was a bespoke proxy struct. Five verbs on a stack meant five structs, each with its own storage, init, `base` projection, and conditional conformances. The mechanical boilerplate hid the distinction between verbs; the vocabulary proliferated without earning its keep.

`Property<Tag, Base>` collapses the boilerplate into one type. Two pieces do the work:

1. **Phantom tag as extension discriminator.** Each accessor namespace has a corresponding empty enum nested on the container (`enum Push {}`, `enum Peek {}`). The enum has no runtime state — it exists only to select which extensions apply via `where Tag == Container.VerbTag`.
2. **CoW-safe coroutine accessor.** The container yields a `Property<Tag, Self>` through `_read` and `_modify`. The `_modify` body follows the five-step recipe (uniqueness → pre-allocate → transfer → clear → restore → yield) that preserves copy-on-write semantics without auxiliary flag state.

Call sites read as verbs — each form discriminated by its tag; each tag has its own extension surface:

```swift
stack.push.back(1)            // push: method accessor via Property
stack.peek.back               // peek: property accessor via Property.Typed
buffer.insert.front(x)        // insert: mutating accessor on ~Copyable via Property.View
container.inspect.count       // read-only on `let`-bound ~Copyable via Property.View.Read
container.forEach { }         // borrow path via Property.Consuming
container.forEach.consuming { } // consume path — same accessor, different method
```

## Variants at a glance

| Variant | Base ownership | Extension shape | Example call site |
|---------|----------------|-----------------|-------------------|
| `Property` | `Copyable` | Methods only (`func back<E>(...)`) | `stack.push.back(x)` |
| `Property.Typed` | `Copyable` | `var` properties needing `Element` | `stack.peek.back` |
| `Property.Consuming` | `Copyable` | Single accessor for borrow AND consume | `container.forEach { }` / `container.forEach.consuming { }` |
| `Property.View` | `~Copyable` | Mutable through `UnsafeMutablePointer<Base>` | `buffer.insert.front(x)` |
| `Property.View.Read` | `~Copyable` | Read-only; supports `let`-bound callers | `let size = container.inspect.count` |

Axis 1: ownership mode (Copyable vs ~Copyable). Axis 2: extension shape (method-case vs property-case, read-only vs mutating). Value generics layer on top via `.Valued<n>` (one compile-time integer) or `.Valued<n>.Valued<m>` (two).

## Key Features

- **Unified accessor abstraction** — A single `Property<Tag, Base>` family replaces bespoke proxy structs in Deque, Heap, Buffer, and peers.
- **Full `~Copyable` support** — Pointer-based `Property.View` and `Property.View.Read` yield borrowed access from non-mutating `_read` accessors on `let`-bound `~Copyable` containers.
- **CoW-safe mutation** — The `_modify` coroutine pattern preserves copy-on-write uniqueness invariants without auxiliary flag state.
- **Consuming accessors** — `Property.Consuming` encodes `.verb.consuming` APIs via a state-tracked class, the only viable pattern under Swift's ownership rules.
- **Zero-cost abstraction** — All views are `~Copyable, ~Escapable` with `@inlinable` accessors; no heap allocation for non-consuming paths.
- **Swift Embedded compatible** — Zero Foundation imports, strict memory safety enabled, no hidden runtime.
- **Swift 6 strict concurrency** — Conditional `Sendable` conformances propagate cleanly through the type family.

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-property-primitives.git", from: "0.1.0")
]
```

Add the umbrella product to your target (recommended for most consumers):

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Property Primitives", package: "swift-property-primitives")
    ]
)
```

The umbrella re-exports every variant. For narrower dependency footprints, depend on an individual variant product instead — `Property View Primitives`, `Property View Read Primitives`, or `Property Consuming Primitives`.

Requires Swift 6.3 and platforms at macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 or the corresponding Linux / Windows toolchain.

## Quick Start

Three example patterns — one per accessor shape.

### Method accessor via `Property<Tag, Base>`

Use `Property<Tag>` when your extensions only need methods (methods can introduce their own generic parameters).

```swift
import Property_Primitives

struct Container<Element: Copyable>: Copyable {
    private var storage: [Element] = []

    enum Push {}

    typealias Property<Tag> = Property_Primitives.Property<Tag, Container<Element>>

    var push: Property<Push> {
        _modify {
            var property: Property<Push> = .init(self)
            self = Container()
            defer { self = property.base }
            yield &property
        }
    }
}

extension Property_Primitives.Property {
    mutating func back<E>(_ element: E)
    where Tag == Container<E>.Push, Base == Container<E> {
        base.storage.append(element)
    }
}

var container = Container<Int>()
container.push.back(42)          // method accessor via Property
```

### Property accessor via `Property.Typed<Element>`

Use `Property.Typed<Element>` when you need `var` properties — the `Element` parameter lives in the extension where-clause.

```swift
extension Container {
    enum Peek {}

    var peek: Property<Peek>.Typed<Element> {
        Property_Primitives.Property.Typed(self)
    }
}

extension Property_Primitives.Property.Typed
where Tag == Container<Element>.Peek, Base == Container<Element> {
    var back: Element? { base.storage.last }
    var count: Int    { base.storage.count }
}

let peeked = container.peek.back // property accessor via Property.Typed
```

### `~Copyable` read-only view via `Property.View.Read`

Use `Property.View.Read` for read-only access on `~Copyable` containers. The `borrowing`-init overload obtains the pointer from a non-mutating context — no `&self` required.

```swift
import Property_Primitives

struct Stack<Element: ~Copyable>: ~Copyable {
    private(set) var count: Int = 0

    enum Inspect {}

    var inspect: Property<Inspect, Self>.View.Read {
        _read {
            yield unsafe Property_Primitives.Property.View.Read(self)
        }
    }
}

extension Property_Primitives.Property.View.Read
where Tag == Stack<Int>.Inspect, Base == Stack<Int> {
    var count: Int { unsafe base.pointee.count }
}

let stack = Stack<Int>()
_ = stack.inspect.count          // ~Copyable view via Property.View.Read
```

## Architecture

Five-layer Swift Institute ecosystem position:

```
Layer 5: Applications
Layer 4: Components
Layer 3: Foundations
Layer 2: Standards
Layer 1: Primitives      ← swift-property-primitives
```

Intra-package target graph (variant decomposition along the ownership / access-model axis):

```
┌───────────────────────────────────────────────────────────┐
│              Property Primitives (umbrella)               │
├────────────────┬──────────────┬──────────────┬────────────┤
│ View Read      │ View         │ Consuming    │            │
│ ~Copyable RO   │ ~Copyable RW │ Copyable     │            │
│ pointer        │ pointer      │ state-tracked│            │
├────────────────┴──────────────┴──────────────┴────────────┤
│ Property Primitives Core (Property, Property.Typed)       │
│                  (internal target, no product)            │
└───────────────────────────────────────────────────────────┘
```

| Target | Contents | Public product |
|--------|----------|----------------|
| `Property Primitives Core` | `Property`, `Property.Typed` (owned, `~Copyable`-preserving base) | — (internal; per [MOD-001]) |
| `Property Consuming Primitives` | `Property.Consuming` (state-tracked, `Copyable`-constrained) | Yes |
| `Property View Primitives` | `Property.View`, `.Typed`, `.Typed.Valued`, `.Typed.Valued.Valued` | Yes |
| `Property View Read Primitives` | `Property.View.Read`, `.Typed`, `.Typed.Valued` | Yes |
| `Property Primitives` | Umbrella — `@_exported` re-export of all four | Yes (canonical consumer import) |
| `Property Primitives Test Support` | Test fixtures + helpers | Yes (test-only) |

The umbrella remains the canonical consumer import. Direct variant imports are an optional follow-up for consumers wanting narrower compile-time boundaries per `[MOD-015]`.

## Platform Support

| Platform         | CI  | Status       |
|------------------|-----|--------------|
| macOS 26         | Yes | Full support |
| Linux            | Yes | Full support |
| Windows          | Yes | Full support |
| iOS/tvOS/watchOS | —   | Supported    |
| Swift Embedded   | —   | Supported    |

## Documentation

The package ships a single DocC catalog — the umbrella's — that carries every per-symbol article, the tutorial, and the cross-cutting topical articles. Variant targets contain source files only; their symbols are documented through the umbrella.

- **Getting Started tutorial** — a seven-minute interactive walkthrough: build a `Stack<Element>` with `push` and `peek` accessors one five-move step at a time.
- **Choosing a Property Variant** — decision matrix across the variants.
- **The CoW-Safe Mutation Recipe** — why the five-step ordering is load-bearing.
- **Phantom Tag Semantics** — what the tag discriminates, and why `Property` and `Tagged` are separate primitives.
- **~Copyable Container Patterns** — mutable `View`, read-only `Read`, and the `.consuming()` namespace-method pattern.
- **Value-Generic Verbosity and the Tag-Enum-View Pattern** — the `.Valued<n>.Valued<m>` chain and the canonical typealias pattern that keeps call sites manageable.

### Distribution

CI produces a single `Property Primitives.doccarchive` via the shared
[`swift-institute/.github` reusable DocC workflow](https://github.com/swift-institute/.github/blob/main/.github/workflows/swift-docs.yml):
`swift build` emits per-module symbol graphs (preserving `@_exported` re-export
doc comments), and `xcrun docc convert` builds the umbrella catalog into one
archive. Consumers enter via the umbrella (`Property Primitives`) — the
landing page, tutorial, topical articles, and full per-symbol reference all
live there. Declaring-module routes (`/documentation/property_primitives_core/property/…`)
remain addressable directly in the archive.

Zero-external-dependencies invariant preserved — no `swift-docc-plugin` in
`Package.swift`. Cross-cutting ecosystem research:
`swift-institute/Research/docc-multi-target-documentation-aggregation.md`.

### Sources layout

- `Sources/Property Primitives/Property Primitives.docc/` — the package's sole DocC catalog: landing page, tutorial, topical articles, every per-symbol article.
- `Sources/Property Primitives Core/` — owned types (`Property`).
- `Sources/Property Typed Primitives/` — owned property-case (`Property.Typed`).
- `Sources/Property Consuming Primitives/` — state-tracked consuming accessor.
- `Sources/Property View Primitives/` — mutable view family.
- `Sources/Property View Read Primitives/` — read-only view family.

Further design rationale: `Research/`. Empirical validation: `Experiments/`.

## License

Apache 2.0. See [LICENSE](LICENSE).
