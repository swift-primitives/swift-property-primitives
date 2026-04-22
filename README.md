# Property Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-primitives/swift-property-primitives/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-primitives/swift-property-primitives/actions/workflows/ci.yml)

Fluent accessor namespaces — `base.verb.method(_:)` — declared as extensions on one `Property<Tag, Base>` family. `Property` is generic over the base type: collections, parsers, I/O sessions, configuration contexts, or any value that benefits from verb-namespaced operations, whether `Copyable` or `~Copyable`.

---

## Key Features

- **One type family, five variants** — `Property`, `Property.Typed`, `Property.Consuming`, `Property.View`, `Property.View.Read` span `Copyable`/`~Copyable` bases and method-vs-property extension shapes.
- **`~Copyable` mutation through `_read`** — `Property.View` yields a writable pointer from a non-mutating `_read` coroutine, so `base.verb.method(x)` works on a `~Copyable` base accessed from a `let` namespace.
- **CoW-safe `_modify` recipe** — The five-step coroutine (uniqueness → transfer → clear → restore → yield) preserves copy-on-write uniqueness without auxiliary flag state.
- **Zero runtime footprint** — All views are `~Copyable, ~Escapable` with `@inlinable` accessors; no heap allocation on non-consuming paths.

---

## Quick Start

### Using Property on a downstream base type

A `~Copyable` fixed-capacity ring buffer with four verb namespaces, each a `Property.View` extension surface — no bespoke proxy structs. This is the call-site shape; declaration shape is shown in the next section.

```swift
import Buffer_Ring_Inline_Primitives

var buffer = Buffer<Int>.Ring.Inline<4>()

buffer.push.back(10)          // Property.View.Typed.Valued — mutating
buffer.push.back(20)          // verb: push
buffer.push.front(0)          // same namespace, different method

let head = buffer.peek.front  // Property.View.Read — non-mutating
let tail = buffer.peek.back   // same namespace, different property

let first = buffer.pop.front()  // separate namespace; removes and returns
```

Four namespaces (`push`, `peek`, `pop`, `remove`) on the same `~Copyable` container, each discriminated by a phantom `Tag` type and each extensible independently. The stdlib has no equivalent shape: it cannot group sibling mutating methods (`.push.back(_:)`, `.push.front(_:)`) under one namespace that third-party code can extend, and it has no analog at all for ~Copyable bases.

Call-sites verbatim from `swift-buffer-primitives`, target `Buffer_Ring_Inline_Primitives`.

### Adopting Property on your own base type

Each verb namespace you expose is one phantom `Tag` type nested on the base type, one accessor property returning `Property<Tag, Self>` (or `Property.Typed<Element>`, or `Property.View<…>`, …), and one extension block on that `Property` variant declaring the methods or properties for that tag. The five-step CoW-safe `_modify` recipe (uniqueness → transfer → clear → restore → yield) is common to every mutating namespace; `Property.View` supplies the `~Copyable` pointer form without further work.

The **Getting Started** tutorial walks through the declaration one tag at a time, builds a `Stack<Element>` with `push.back(_:)` and `peek.back`, and ends with the final-step file mirrored by `Tests/Tutorial/` so tutorial-step API drift breaks the test suite.

---

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-property-primitives.git", from: "0.1.0")
]
```

Add the umbrella product to your target (recommended for most consumers — re-exports every variant):

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Property Primitives", package: "swift-property-primitives")
    ]
)
```

For narrower compile-time surface, depend on an individual variant product — `Property View Primitives`, `Property View Read Primitives`, or `Property Consuming Primitives`.

Requires Swift 6.3.1 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the corresponding Linux / Windows toolchain).

---

## Architecture

Intra-package target graph — variant decomposition along the ownership / access-model axis:

```
┌────────────────────────────────────────────────────────────┐
│              Property Primitives (umbrella)                │
├─────────────────┬──────────────┬──────────────┬────────────┤
│ View Read       │ View         │ Consuming    │ Typed      │
│ ~Copyable RO    │ ~Copyable RW │ Copyable     │ Copyable   │
│ pointer         │ pointer      │ state-tracked│ property   │
├─────────────────┴──────────────┴──────────────┴────────────┤
│ Property Primitives Core (Property)                        │
│                   (internal; no product)                   │
└────────────────────────────────────────────────────────────┘
```

| Target | Contents | Public product |
|--------|----------|----------------|
| `Property Primitives Core` | `Property` (owned base, `~Copyable`-preserving) | internal |
| `Property Typed Primitives` | `Property.Typed` | yes |
| `Property Consuming Primitives` | `Property.Consuming` (state-tracked) | yes |
| `Property View Primitives` | `Property.View`, `.Typed`, `.Typed.Valued`, `.Typed.Valued.Valued` | yes |
| `Property View Read Primitives` | `Property.View.Read`, `.Typed`, `.Typed.Valued` | yes |
| `Property Primitives` | Umbrella — `@_exported` re-export of all variants | yes (canonical import) |
| `Property Primitives Test Support` | Test fixtures | yes (test-only) |

---

## Platform Support

| Platform         | CI  | Status       |
|------------------|-----|--------------|
| macOS 26         | Yes | Full support |
| Linux            | Yes | Full support |
| Windows          | Yes | Full support |
| iOS/tvOS/watchOS | —   | Supported    |
| Swift Embedded   | —   | Supported    |

---

## Documentation

DocC — tutorials, topical articles, and per-symbol reference — ships as a single archive for the umbrella and is available on [Swift Package Index](https://swiftpackageindex.com/swift-primitives/swift-property-primitives/main/documentation/property_primitives) after publication.

Enter via the umbrella's landing page for:

- **Getting Started** — a seven-minute interactive tutorial
- **Choosing a Property Variant** — decision matrix across the five variants
- **The CoW-Safe Mutation Recipe** — why the five-step ordering matters
- **Phantom Tag Semantics** — what the tag discriminates and why `Property` and `Tagged` are separate primitives
- **`~Copyable` Base Patterns** — mutable `View`, read-only `Read`, and the consuming namespace-method pattern

---

## License

Apache 2.0. See [LICENSE](LICENSE).
