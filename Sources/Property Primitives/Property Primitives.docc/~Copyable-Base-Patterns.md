# ~Copyable Base Patterns

@Metadata {
    @TitleHeading("Swift Primitives")
}

`~Copyable` bases cannot use the Copyable-world
<doc:CoW-Safe-Mutation-Recipe> directly — the five-step recipe transfers the
base by value, which requires copy semantics. The `Inout` and `Borrow`
variants replace by-value transfer with a tagged exclusive borrow
(`Ownership.Inout<Base>`) or shared borrow (`Ownership.Borrow<Base>`). The
patterns below document the four accessor shapes available for `~Copyable`
base types.

## Pattern 1 — mutable method-case accessor

Use ``Property/Inout-swift.struct`` with `mutating _read` and `mutating _modify`
accessors. The mutating requirement is load-bearing: `&self` is required to
construct the exclusive borrow, and `&self` exists only in mutating contexts.

```swift
extension Buffer where Element: ~Copyable {
    public typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
}

extension Buffer where Element: ~Copyable {
    public enum Insert {}

    public var insert: Property<Insert>.Inout {
        mutating _read {
            yield Property<Insert>.Inout(&self)
        }
        mutating _modify {
            var accessor = Property<Insert>.Inout(&self)
            yield &accessor
        }
    }
}

extension Property.Inout
where Tag == Buffer<Element>.Insert, Base == Buffer<Element>, Element: ~Copyable {
    public mutating func front(_ element: consuming Element) {
        base.value.push(front: element)
    }
}

// Call site:
buffer.insert.front(element)
```

**When to use.** `~Copyable` base types where the accessor bodies mutate or
consume elements. The method-level generic parameter (`func front<E>`) is not
needed; extensions bind `Element` through the extension where-clause.

## Pattern 2 — property-case accessor with `Element` in scope

Use ``Property/Inout-swift.struct/Typed``. Same exclusive-borrow mechanism, with
an `Element` type parameter so `var` extensions can bind it.

```swift
extension Container where Element: ~Copyable {
    public typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
}

extension Container where Element: ~Copyable {
    public enum Access {}

    public var access: Property<Access>.Inout.Typed<Element> {
        mutating _read {
            yield Property<Access>.Inout.Typed(&self)
        }
        mutating _modify {
            var accessor = Property<Access>.Inout.Typed<Element>(&self)
            yield &accessor
        }
    }
}

extension Property.Inout.Typed
where Tag == Container<Element>.Access, Base == Container<Element>,
      Element: ~Copyable
{
    public var count: Int { base.value.count }
}
```

**When to use.** `~Copyable` base types where extensions return `Element?`
or otherwise bind `Element` in their signature.

## Pattern 3 — read-only access (supports `let`-bound callers)

Use ``Property/Borrow`` with a *non-mutating* `_read` accessor. This works on
`let`-bound containers; the mutable `Inout` accessor does not.

```swift
extension Container where Self: ~Copyable {
    public typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
}

extension Container where Self: ~Copyable {
    public enum Inspect {}

    public var inspect: Property<Inspect>.Borrow {
        _read {
            yield Property<Inspect>.Borrow(self)
        }
    }
}

extension Property.Borrow
where Tag == Container.Inspect, Base == Container {
    public var count: Int { base.value.count }
}

// Call site — works on `let` bindings:
let container = Container()
let size = container.inspect.count
```

**When to use.** `~Copyable` base types where extensions do not mutate; the
base may be `let`-bound at the call site. For read-only access on
property-case extensions needing `Element` in scope, switch to
``Property/Borrow/Typed``.

## Pattern 4 — non-mutating context on stored properties

Use the static ``Property/pointer(to:_:)`` helper to obtain a pointer to
a stored property from a non-mutating context. The closure pattern takes
`borrowing` parameters — no `&self` required. The helper lives on
`Property` (not `Property.Inout`) because `Inout` itself requires `&self`;
this escape hatch exists for the contexts where `Inout` is unreachable.

```swift
struct SmallArray<Element>: Sequence {
    var _inlineStorage: (Element?, Element?, Element?, Element?)
    var _count: Int
}

extension SmallArray {
    typealias Property<Tag> = Property_Primitives.Property<Tag, Self>
}

extension SmallArray {
    enum Inline {}

    borrowing func makeIterator() -> Iterator {
        Property<Inline>.pointer(to: _inlineStorage) { ptr in
            Iterator(base: ptr, count: _count)
        }
    }
}
```

**When to use.** Protocol conformances that require non-mutating accessors
(`Sequence.makeIterator()`, `Collection.subscript` getters), `borrowing`
functions, and other non-mutating contexts that need pointer access to a
stored property.

**Limitation.** The pointer is only valid inside the closure body; it cannot
escape. Values constructed from the pointer (iterators, views) must also not
escape the closure — copy any needed data out, or structure the API so the
closure does the work.

## The init contract

`Property.Inout` ships two init overloads, distinguishing safe and unsafe
construction paths:

```swift
public init(_ base: inout Base)        // Safe — used in `mutating _read` / `_modify`.
public init(_ base: borrowing Base)    // @unsafe — used in `deinit` and other borrowing contexts.
```

The `inout Base` init is the canonical path for accessor bodies; `&self` is
available there. The `borrowing Base` init is `@unsafe` because it casts
away `const` to materialise an `Ownership.Inout`; the caller must guarantee
mutation through the accessor is valid at the call site.

`Property.Borrow` ships a single safe init:

```swift
public init(_ base: borrowing Base)    // Safe — used in non-mutating `_read`.
```

Borrow does not need a mutating overload — its access is read-only, so
`borrowing self` is sufficient at every call site (including `let` bindings).

## `.consuming()` namespace-method pattern on Inout

For `~Copyable` bases, the dual-call-site idiom
(`.verb { }` vs `.verb.consuming { }`) does NOT use ``Property/Consume``
(which requires `Base: Copyable`). Instead, add a `.consuming` namespace
method to the Inout's extensions:

```swift
extension Property.Inout
where Tag == Buffer<Element>.ForEach, Base == Buffer<Element>, Element: ~Copyable {
    public func callAsFunction(_ body: (borrowing Element) -> Void) {
        // Borrow path — iterate without emptying.
    }

    public mutating func consuming(_ body: (consuming Element) -> Void) {
        // Consume path — empties the container.
    }
}
```

## See Also

- ``Property/Inout-swift.struct``
- ``Property/Inout-swift.struct/Typed``
- ``Property/Borrow``
- ``Property/Borrow/Typed``
- <doc:Choosing-A-Property-Variant>
- <doc:Value-Generic-Verbosity-And-The-Tag-Enum-Accessor-Pattern>
