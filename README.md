# Property

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-atoms/swift-property/actions/workflows/ci.yml/badge.svg)](https://github.com/swift-atoms/swift-property/actions/workflows/ci.yml)

Fluent accessor namespaces — `base.namespace.method(_:)` — declared as extensions on one `Property<Tag, Base>` family. `Property` is generic over the base type: collections, parsers, I/O sessions, configuration contexts, or any value that benefits from namespaced operations, whether `Copyable` or `~Copyable`.

Use `Property<Tag, Base>` for accessor namespaces on a base value (this package). Use [`Tagged<Tag, RawValue>`](https://github.com/swift-atoms/swift-tagged) for domain-typed raw values (sibling primitive).

---

## Key Features

- **One type family, five variants** — `Property`, `Property.Typed`, `Property.Consume`, `Property.Inout`, and `Property.Borrow` span `Copyable`/`~Copyable` bases and method-vs-property extension shapes.
- **`~Copyable` mutation through `_read`** — `Property.Inout` yields a writable pointer from a non-mutating `_read` coroutine, so `base.namespace.method(x)` works on a `~Copyable` base accessed from a `let` namespace.
- **CoW-safe `_modify` recipe** — The five-step coroutine (uniqueness → transfer → clear → restore → yield) preserves copy-on-write uniqueness without auxiliary flag state.
- **Zero runtime footprint** — All views are `~Copyable, ~Escapable` with `@inlinable` accessors; no heap allocation on non-consuming paths.

---

## Quick Start

A `Stack<Element>` exposes a `peek` namespace via a `Property.Typed` accessor. The phantom `Peek` tag selects which property extensions apply at the call site:

```swift
import Property_Typed

public struct Stack<Element: Copyable>: Copyable {
    internal var _storage: [Element]
    public init(_ elements: [Element] = []) { self._storage = elements }
}

extension Stack {
    public typealias Property<Tag> = Property::Property<Tag, Stack<Element>>
}

extension Stack {
    public enum Peek {}

    public var peek: Property<Peek>.Typed<Element> {
        Property<Peek>.Typed(self)
    }
}

extension Property::Property.Typed where Tag == Stack<Element>.Peek, Base == Stack<Element> {
    public var back: Element?  { base._storage.last }
    public var depth: Int      { base._storage.count }
    public var isEmpty: Bool   { base._storage.isEmpty }
}

let stack = Stack([1, 2, 3])
print(stack.peek.back)      // Optional(3)
print(stack.peek.depth)     // 3
print(stack.peek.isEmpty)   // false
```

Four pieces: a `Stack` with stored storage and the canonical init in its type body; a foundational `Property<Tag>` typealias adopting the library type into Stack's namespace (reused by every namespace Stack declares); a per-namespace extension nesting the phantom `Peek` tag and the single-line `peek` accessor; a constrained extension on `Property::Property.Typed` adding properties to the namespace. Third-party code can extend `stack.peek.*` with additional properties via more `extension Property::Property.Typed where …` blocks without owning Stack — that's the value over a hand-rolled `var peek: PeekNamespace`.

For *mutating* namespaces (`stack.push.back(10)` and friends), the accessor uses a `_read` / `_modify` pair with a CoW-safe transfer recipe that preserves copy-on-write semantics. See the [Getting Started tutorial](https://swiftpackageindex.com/swift/swift-property/main/tutorials/property/gettingstarted) for the full Stack with `push` and `pop`, and the [CoW-Safe Mutation Recipe](https://swiftpackageindex.com/swift/swift-property/main/documentation/property/cow-safe-mutation-recipe) article for the recipe's five steps.

---

## Installation

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/swift-atoms/swift-property.git", branch: "main")
]
```

Add the specific products your target uses:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Property Typed", package: "swift-property"),
        .product(name: "Property Inout", package: "swift-property"),
    ]
)
```

Available products are the base `Property` module and the focused `Property Carrier`, `Property Typed`, `Property Consume`, `Property Inout`, and `Property Borrow` layers.

Requires Swift 6.3.1 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the corresponding Linux / Windows toolchain).

---

## Architecture

The package exposes a base module plus focused layers along the ownership and access-model axes. Each layer depends on and re-exports the base module; there is no all-variants convergence product.

| Product | Contents | When to import |
|---------|----------|----------------|
| `Property` | `Property<Tag, Base>` | Base value and namespace type |
| `Property Carrier` | `Property: Carrier.Protocol` | Carrier integration |
| `Property Typed` | `Property.Typed` | Phantom-typed `Copyable` property values |
| `Property Consume` | `Property.Consume` (state-tracked) | Consume-style namespaces over `Copyable` bases |
| `Property Inout` | `Property.Inout`, `.Typed`, `.Typed.Valued`, `.Typed.Valued.Valued` | Mutating accessors over `~Copyable` bases |
| `Property Borrow` | `Property.Borrow`, `.Typed`, `.Typed.Valued` | Read-only accessors over `~Copyable` bases |
| `Property Test Support` | Test fixtures | Test target only |

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

DocC ships on [Swift Package Index](https://swiftpackageindex.com/swift/swift-property/main/documentation/property) after publication. Two entry points:

- **Getting Started** — a seven-minute interactive tutorial that builds the full Stack from this Quick Start.
- **Choosing a Property Variant** — decision matrix across the five variants.

---

## License

Apache 2.0. See [LICENSE](LICENSE).
