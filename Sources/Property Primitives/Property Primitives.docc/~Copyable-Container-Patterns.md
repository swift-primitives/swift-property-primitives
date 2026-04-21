# ~Copyable Container Patterns

@Metadata {
    @TitleHeading("Swift Primitives")
}

`~Copyable` containers cannot use the Copyable-world
<doc:CoW-Safe-Mutation-Recipe> directly — the five-step recipe transfers the
base by value, which requires copy semantics. The View family replaces
by-value transfer with `UnsafeMutablePointer<Base>` (mutable) or
`UnsafePointer<Base>` (read-only). The patterns below document the three
accessor shapes that cover the `~Copyable` container space.

## Pattern 1 — mutable method-case accessor

Use ``Property/View-swift.struct`` with `mutating _read` and `mutating _modify`
accessors. The mutating requirement is load-bearing: `&self` is required to
construct the `UnsafeMutablePointer`, and `&self` exists only in mutating
contexts.

```swift
extension Buffer where Element: ~Copyable {
    public typealias Property<Tag> = Property_Primitives.Property<Tag, Self>

    public enum Insert {}

    public var insert: Property<Insert>.View {
        mutating _read {
            yield unsafe Property<Insert>.View(&self)
        }
        mutating _modify {
            var view = unsafe Property<Insert>.View(&self)
            yield &view
        }
    }
}

extension Property_Primitives.Property.View
where Tag == Buffer<Element>.Insert, Base == Buffer<Element>, Element: ~Copyable {
    public mutating func front(_ element: consuming Element) {
        unsafe base.pointee.push(front: element)
    }
}

// Call site:
buffer.insert.front(element)
```

**When to use.** `~Copyable` containers where the accessor bodies mutate or
consume elements. The method-level generic parameter (`func front<E>`) is not
needed; extensions bind `Element` through the extension where-clause.

## Pattern 2 — property-case accessor with `Element` in scope

Use ``Property/View-swift.struct/Typed``. Same pointer-based mechanism, with
an `Element` type parameter so `var` extensions can bind it.

```swift
extension Container where Element: ~Copyable {
    public typealias Property<Tag> = Property_Primitives.Property<Tag, Self>

    public enum Access {}

    public var access: Property<Access>.View.Typed<Element> {
        mutating _read {
            yield unsafe Property<Access>.View.Typed(&self)
        }
        mutating _modify {
            var view = unsafe Property<Access>.View.Typed<Element>(&self)
            yield &view
        }
    }
}

extension Property_Primitives.Property.View.Typed
where Tag == Container<Element>.Access, Base == Container<Element>,
      Element: ~Copyable
{
    public var count: Int { unsafe base.pointee.count }
}
```

**When to use.** `~Copyable` containers where extensions return `Element?`
or otherwise bind `Element` in their signature.

## Pattern 3 — read-only access (supports `let`-bound callers)

Use ``Property/View-swift.struct/Read`` with a *non-mutating* `_read`
accessor and the `init(_ base: borrowing Base)` overload. This works on
`let`-bound containers; the mutable View does not.

```swift
extension Container where Self: ~Copyable {
    public typealias Property<Tag> = Property_Primitives.Property<Tag, Self>

    public enum Inspect {}

    public var inspect: Property<Inspect>.View.Read {
        _read {
            yield unsafe Property<Inspect>.View.Read(self)  // borrowing-init, unlabeled
        }
    }
}

extension Property_Primitives.Property.View.Read
where Tag == Container.Inspect, Base == Container {
    public var count: Int { unsafe base.pointee.count }
}

// Call site — works on `let` bindings:
let container = Container()
let size = container.inspect.count
```

**When to use.** `~Copyable` containers where extensions do not mutate; the
container may be `let`-bound at the call site. For read-only access on
property-case extensions needing `Element` in scope, switch to
``Property/View-swift.struct/Read/Typed``.

## Pattern 4 — non-mutating context on stored properties

Use the static ``Property/View-swift.struct/pointer(to:_:)`` helper to
obtain a pointer to a stored property from a non-mutating context. The
closure pattern takes `borrowing` parameters — no `&self` required.

```swift
struct SmallArray<Element>: Sequence {
    typealias Property<Tag> = Property_Primitives.Property<Tag, Self>

    enum Inline {}

    var _inlineStorage: (Element?, Element?, Element?, Element?)
    var _count: Int

    borrowing func makeIterator() -> Iterator {
        Property<Inline>.View.pointer(to: _inlineStorage) { ptr in
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

## The borrowing-init convention

Every `Property.View*` type ships two `init` overloads:

```swift
public init(_ base: UnsafeMutablePointer<Base>)  // Or UnsafePointer<Base> for Read.
public init(_ base: borrowing Base)
```

Both are called **without the `borrowing:` argument label** — type-based
overload resolution disambiguates them. The pointer init takes a pointer; the
borrowing init takes a `borrowing` value. Swift picks the right one from the
argument type alone.

```swift
// ✓ Correct:
yield unsafe Property.View.Read(self)      // borrowing init (self is the base)
yield unsafe Property.View.Read(pointer)   // pointer init (pointer is UnsafePointer)

// ❌ Stale 0.1.0-era syntax — label was dropped:
yield unsafe Property.View.Read(borrowing: self)
```

The label dropped in 0.1.0 because it was redundant. Swift does not have a
call-site `borrowing x` expression form — only `consume x` and `copy x` exist
as expression-level ownership markers — so the argument label could not
offer expression-level explicitness either.

## `~Escapable` state

As of 2026-03-22, the Property.View* types are `~Copyable` but NOT
`~Escapable`. An earlier design had `~Escapable` + `@_lifetime(borrow base)`
for defence-in-depth against view escape, but that combination triggered a
SIL CopyPropagation false positive (`OSSACanonicalizeOwned` bail-out on
`mark_dependence`) that required unbounded `@_optimize(none)` workarounds on
downstream `@inlinable` consumers.

The coroutine scope (`begin_apply` / `end_apply` at SIL level) already
confines the view's lifetime to the `_read` / `_modify` body. `~Copyable`
prevents copies. The only escape path would be direct `Property.View(&ptr)`
construction in `unsafe` territory where compiler-provided lifetime
guarantees are already absent. Removing `~Escapable` eliminated the
workarounds at the cost of a theoretical escape window that no real code
was hitting.

The `~Escapable` annotation should be restored when the compiler bug
(`OSSACanonicalizeOwned` `mark_dependence` canonicalisation TODO) is fixed.
Monitor the standalone reproducer at
`swift-buffer-primitives/Experiments/copypropagation-nonescapable-mark-dependence/`.

## `.consuming()` namespace-method pattern on View

For `~Copyable` containers, the dual-call-site idiom
(`.verb { }` vs `.verb.consuming { }`) does NOT use ``Property/Consuming``
(which requires `Base: Copyable`). Instead, add a `.consuming` namespace
method to the View's extensions:

```swift
extension Property_Primitives.Property.View
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

- ``Property/View-swift.struct``
- ``Property/View-swift.struct/Typed``
- ``Property/View-swift.struct/Read``
- ``Property/View-swift.struct/Read/Typed``
- <doc:Choosing-A-Property-Variant>
- <doc:Value-Generic-Verbosity-And-The-Tag-Enum-View-Pattern>
- [Property.View ~Escapable Removal](../../../Research/property-view-escapable-removal.md) — The CopyPropagation decision record. Status: DECISION.
- [Borrowing Label Drop Rationale](../../../Research/borrowing-label-drop-rationale.md) — Why the `borrowing:` label was dropped in 0.1.0. Status: DECISION.
