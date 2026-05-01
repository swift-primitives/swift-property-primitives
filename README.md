# Property Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-primitives/swift-property-primitives/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-primitives/swift-property-primitives/actions/workflows/ci.yml)

Fluent accessor namespaces — `base.namespace.method(_:)` — declared as extensions on one `Property<Tag, Base>` family. `Property` is generic over the base type: collections, parsers, I/O sessions, configuration contexts, or any value that benefits from namespaced operations, whether `Copyable` or `~Copyable`.

Use `Property<Tag, Base>` for accessor namespaces on a base value (this package). Use [`Tagged<Tag, RawValue>`](https://github.com/swift-primitives/swift-tagged-primitives) for domain-typed raw values (sibling primitive).

---

## Key Features

- **One type family, five variants** — `Property`, `Property.Typed`, `Property.Consuming`, `Property.View`, `Property.View.Read` span `Copyable`/`~Copyable` bases and method-vs-property extension shapes.
- **`~Copyable` mutation through `_read`** — `Property.View` yields a writable pointer from a non-mutating `_read` coroutine, so `base.namespace.method(x)` works on a `~Copyable` base accessed from a `let` namespace.
- **CoW-safe `_modify` recipe** — The five-step coroutine (uniqueness → transfer → clear → restore → yield) preserves copy-on-write uniqueness without auxiliary flag state.
- **Zero runtime footprint** — All views are `~Copyable, ~Escapable` with `@inlinable` accessors; no heap allocation on non-consuming paths.

---

## Quick Start

A `Stack<Element>` exposes a `peek` namespace via a `Property.Typed` accessor. The phantom `Peek` tag selects which property extensions apply at the call site:

```swift
import Property_Primitives

public struct Stack<Element: Copyable>: Copyable {
    internal var _storage: [Element]
    public init(_ elements: [Element] = []) { self._storage = elements }
}

extension Stack {
    public typealias Property<Tag> = Property_Primitives.Property<Tag, Stack<Element>>
}

extension Stack {
    public enum Peek {}

    public var peek: Property<Peek>.Typed<Element> {
        Property<Peek>.Typed(self)
    }
}

extension Property.Typed where Tag == Stack<Element>.Peek, Base == Stack<Element> {
    public var back: Element?  { base._storage.last }
    public var depth: Int      { base._storage.count }
    public var isEmpty: Bool   { base._storage.isEmpty }
}

let stack = Stack([1, 2, 3])
print(stack.peek.back)      // Optional(3)
print(stack.peek.depth)     // 3
print(stack.peek.isEmpty)   // false
```

Four pieces: a `Stack` with stored storage and the canonical init in its type body; a foundational `Property<Tag>` typealias adopting the library type into Stack's namespace (reused by every namespace Stack declares); a per-namespace extension nesting the phantom `Peek` tag and the single-line `peek` accessor; a constrained extension on `Property.Typed` adding properties to the namespace. Third-party code can extend `stack.peek.*` with additional properties via more `extension Property.Typed where …` blocks without owning Stack — that's the value over a hand-rolled `var peek: PeekNamespace`.

For *mutating* namespaces (`stack.push.back(10)` and friends), the accessor uses a `_read` / `_modify` pair with a CoW-safe transfer recipe that preserves copy-on-write semantics. See the [Getting Started tutorial](https://swiftpackageindex.com/swift-primitives/swift-property-primitives/main/tutorials/property_primitives/gettingstarted) for the full Stack with `push` and `pop`, and the [CoW-Safe Mutation Recipe](https://swiftpackageindex.com/swift-primitives/swift-property-primitives/main/documentation/property_primitives/cow-safe-mutation-recipe) article for the recipe's five steps.

---

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-property-primitives.git", branch: "main")
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

| Product | Contents | When to import |
|---------|----------|----------------|
| `Property Primitives` | Umbrella — `@_exported` re-export of all variants | Prototyping, tests, small consumers willing to pay the umbrella surface cost |
| `Property Typed Primitives` | `Property.Typed` | Phantom-typed `Copyable` property values |
| `Property Consuming Primitives` | `Property.Consuming` (state-tracked) | Consume-style namespaces over `~Copyable` bases |
| `Property View Primitives` | `Property.View`, `.Typed`, `.Typed.Valued`, `.Typed.Valued.Valued` | Borrow-style mutating accessors over `~Copyable` bases |
| `Property View Read Primitives` | `Property.View.Read`, `.Typed`, `.Typed.Valued` | Borrow-style read-only accessors |
| `Property Primitives Test Support` | Test fixtures | Test target only |

Internal `Property Primitives Core` target hosts the `Property` type; not a public product.

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

DocC ships on [Swift Package Index](https://swiftpackageindex.com/swift-primitives/swift-property-primitives/main/documentation/property_primitives) after publication. Two entry points:

- **Getting Started** — a seven-minute interactive tutorial that builds the full Stack from this Quick Start.
- **Choosing a Property Variant** — decision matrix across the five variants.

---

## License

Apache 2.0. See [LICENSE](LICENSE).
