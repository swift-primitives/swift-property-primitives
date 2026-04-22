---
name: property-primitives
description: |
  Fluent accessor property type primitives.
  ALWAYS apply when adding fluent accessor namespaces (`container.push.back`,
  `container.peek.front`, `container.forEach.consuming { }`, etc.) to a container type,
  whether `Copyable` or `~Copyable`.

layer: implementation

requires:
  - code-surface

applies_to:
  - swift
---

# Property Primitives

`Property<Tag, Base>` gives your container type a fluent accessor namespace without
you having to write a bespoke proxy struct for each verb. One container can expose
many namespaces (`push`, `pop`, `peek`, `insert`, `forEach`) — each is a `Property`
specialized on a phantom `Tag` type, each with its own extension surface.

This skill tells you — the **consumer** of `swift-property-primitives` — how to add
those accessors to your type and which variant to reach for.

---

## Decision: Which variant do I use?

### [PRP-001] Pick your variant

**Statement**: Pick the `Property` variant by two questions — *is my `Base` `Copyable`
or `~Copyable`?*, and *do my extensions need an `Element` type parameter in scope for
`var` properties?*

| Container is… | Extension shape | Use |
|---------------|-----------------|-----|
| `Copyable` | Methods only (`func back<E>(...)`) | ``Property_Primitives/Property`` |
| `Copyable` | Properties (`var back: E?`) | ``Property_Primitives/Property/Typed`` |
| `Copyable` | Same call supports `.verb { }` AND `.verb.consuming { }` | ``Property_Primitives/Property/Consuming`` |
| `~Copyable` | Mutable pointer access | ``Property_Primitives/Property/View-swift.struct`` |
| `~Copyable` | Mutable + `Element` in scope | ``Property_Primitives/Property/View-swift.struct/Typed`` |
| `~Copyable` | Read-only access (including `let` bindings) | ``Property_Primitives/Property/View-swift.struct/Read`` |
| `~Copyable` | Read-only + `Element` in scope | ``Property_Primitives/Property/View-swift.struct/Read/Typed`` |
| Has one value generic (e.g. `capacity`) | Append `.Valued<n>` | `…View.Typed<E>.Valued<n>` |
| Has two value generics | Append `.Valued<n>.Valued<m>` | `…View.Typed<E>.Valued<n>.Valued<m>` |

**Rationale**: Swift methods can introduce their own type parameters at the call site;
property declarations cannot. `.Typed<Element>` smuggles the element type into scope
so property extensions can bind it. Pointer variants (`.View.*`) are mandatory for
`~Copyable` containers because ownership transfer through a borrowing property
accessor is impossible.

**Cross-references**: For the long-form decision matrix, CoW mutation recipe, and
parameter-order rationale, see the `Property` DocC article (via the umbrella's
catalogue).

---

## Setup: tags, typealias, imports

### [PRP-002] Define tags as empty enums nested in your container

**Statement**: Each accessor namespace on your container MUST have a corresponding
empty enum tag, declared as a nested type on the container.

**Correct**:
```swift
extension Stack where Element: Copyable {
    public enum Push {}
    public enum Pop {}
    public enum Peek {}
}
```

**Incorrect**:
```swift
// ❌ Tag declared at top level — not discoverable via dot-navigation.
public enum StackPush {}

// ❌ Tag carries a *Tag suffix (forbidden per feedback_no_tag_suffix).
public enum PushTag {}

// ❌ Tag has cases or stored values — tags are phantom, empty.
public enum Push { case immediate }
```

**Rationale**: Nested tags are reachable via `Stack.Push` in extension where-clauses
and at call sites. Top-level tags pollute the consuming module's namespace. The
tag's only job is to discriminate extensions — it has no runtime state, so use an
empty enum (`enum Push {}`), not a struct or class.

---

### [PRP-003] Define a `Property<Tag>` typealias on the container

**Statement**: Each container that exposes Property accessors MUST define a
`typealias Property<Tag>` scoped to itself, binding `Base` to `Container<Element>`.

**Correct**:
```swift
extension Stack where Element: Copyable {
    public typealias Property<Tag> = Property_Primitives.Property<Tag, Stack<Element>>
}
```

Then, at accessor declarations, write the short form:
```swift
var push: Property<Push> { ... }                    // method-case
var peek: Property<Peek>.Typed<Element> { ... }     // property-case
```

**Incorrect**:
```swift
// ❌ Repeats Base at every accessor — verbose, drift-prone.
var push: Property_Primitives.Property<Push, Stack<Element>> { ... }
```

**Rationale**: The typealias eliminates the `Base` repetition at every accessor
declaration in your container. Scoping it to the container-with-constraint
(`where Element: Copyable`) prevents accidental spillover to other type contexts.

---

### [PRP-004] Import the umbrella

**Statement**: Consumers SHOULD `import Property_Primitives` (the umbrella). Narrow
variant imports are available for advanced consumers but are not required.

**Correct**:
```swift
import Property_Primitives
```

**Narrow variant imports** (optional, when a consumer wants to minimise compile-time
boundaries). `Property_Primitives_Core` is internal per `[MOD-001]` and NOT a product;
consumers cannot import it directly. Pick the variant product that covers your needed
type surface — each variant transitively re-exports Core:

| Import | For consumers who only need… |
|--------|------------------------------|
| `Property_Typed_Primitives` | `Property<Tag, Base>` + `Property<Tag, Base>.Typed<Element>` (owned method-case and property-case on `Copyable` base) |
| `Property_Consuming_Primitives` | `Property<Tag, Base>.Consuming<Element>` (borrow + consume on `Copyable` base) |
| `Property_View_Primitives` | `Property<Tag, Base>.View` family (mutable pointer access on `~Copyable` base) |
| `Property_View_Read_Primitives` | `Property<Tag, Base>.View.Read` family (read-only pointer access; supports `let`-bound `~Copyable`) |

**Rationale**: The umbrella `@_exported public import`s every variant, so `import
Property_Primitives` makes the full type family available. Narrow imports work for
consumers who need the finer-grained dependency graph but are not required for
correctness. Consumers who only need the owned method-case `Property<Tag, Base>`
(no `.Typed`, `.Consuming`, or `.View`) do not have a sub-umbrella narrow option —
Core is not directly importable; the umbrella is the smallest public entry in that case.

---

## Pattern: method-case accessor (Copyable)

### [PRP-005] Method extensions use `Property<Tag>`

**Statement**: When your extensions are methods that introduce their own generic
parameters, use `Property<Tag>` and extend the `Property` type.

**Correct**:
```swift
extension Stack where Element: Copyable {
    public var push: Property<Push> {
        _modify {
            makeUnique()                   // 1. Uniqueness before transfer
            reserve(count + 1)             // 2. Pre-allocate if needed
            var property: Property<Push> = .init(self)
            self = Stack()                 // 3. Clear self
            defer { self = property.base } // 4. Restore on exit
            yield &property                // 5. Yield for mutation
        }
    }
}

extension Property_Primitives.Property {
    @inlinable
    public mutating func back<E>(_ element: E)
    where Tag == Stack<E>.Push, Base == Stack<E> {
        base.append(element)
    }
}

// Call site:
stack.push.back(element)
```

**Rationale**: `Property<Tag>` doesn't carry `Element` in its signature, so
extensions on it cannot bind `Element` in a property where-clause. But they CAN
bind it via a method-level generic (`func back<E>(...)`) — that's what makes
method extensions the right shape for this case.

**Cross-references**: `[PRP-007]` for the CoW-safe `_modify` recipe expansion.

---

## Pattern: property-case accessor (Copyable)

### [PRP-006] Property extensions use `Property<Tag>.Typed<Element>`

**Statement**: When your extensions are `var` properties that need `Element` in
scope (e.g. return `Element?`), use `Property<Tag>.Typed<Element>` and extend
`Property.Typed`.

**Correct**:
```swift
extension Stack where Element: Copyable {
    public var peek: Property<Peek>.Typed<Element> {
        Property_Primitives.Property.Typed(self)
    }
}

extension Property_Primitives.Property.Typed
where Tag == Stack<Element>.Peek, Base == Stack<Element> {
    @inlinable public var back: Element?  { base.last }
    @inlinable public var front: Element? { base.first }
    @inlinable public var count: Int      { base.count }
}

// Call site:
let last = stack.peek.back
let size = stack.peek.count
```

**Incorrect**:
```swift
// ❌ No way to bind Element in a property extension on plain Property.
extension Property_Primitives.Property
where Tag == Stack<Element>.Peek, Base == Stack<Element> {
    var back: Element? { ... }   // compile error — Element not in scope.
}
```

**Rationale**: Swift properties cannot introduce their own generic parameters
(methods can, `func back<E>(...)` works). `Property.Typed<Element>` carries
`Element` in its type signature, so extensions on `Property.Typed` have `Element`
available in their where-clauses.

---

## Pattern: CoW-safe `_modify` recipe

### [PRP-007] Use the five-step `_modify` recipe for CoW containers

**Statement**: `_modify` accessors on CoW-safe containers MUST follow the five-step
recipe — uniqueness check → pre-allocate → transfer → clear self → restore on defer
→ yield. The ordering is load-bearing.

**Correct**:
```swift
var push: Property<Push> {
    _modify {
        makeUnique()                   // 1. Force uniqueness BEFORE transfer
        reserve(count + 1)             // 2. Pre-allocate if needed
        var property: Property<Push> = .init(self)
        self = Stack()                 // 3. Clear self to release reference
        defer { self = property.base } // 4. Restore on scope exit
        yield &property                // 5. Yield for mutation
    }
}
```

**Incorrect**:
```swift
// ❌ Transfer before uniqueness — proxy may hold shared reference.
var property = Property<Push>(self)
makeUnique()  // Too late; proxy already transferred.
```

**Rationale**: If `makeUnique()` runs *after* the transfer, the proxy holds a
reference to potentially shared storage, defeating copy-on-write. The specific
`self = Stack()` (step 3) releases the caller's reference so that only the proxy
holds storage during the yield, preserving uniqueness for the mutation body.

---

## Pattern: ~Copyable pointer view

### [PRP-008] `~Copyable` containers use `Property.View` with mutating accessors

**Statement**: For `~Copyable` containers, use `Property<Tag>.View` (or
`.Typed<Element>` / `.Typed.Valued<n>` variants) with `mutating _read` and
`mutating _modify` accessors, paired with the container-level
`typealias Property<Tag>` per `[PRP-003]`. The accessor MUST be mutating
because `&self` is required to construct the `UnsafeMutablePointer`.

**Correct**:
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
    @inlinable public mutating func front(_ element: consuming Element) {
        unsafe base.pointee.pushFront(element)
    }
}

// Call site:
buffer.insert.front(element)
```

**Incorrect**:
```swift
// ❌ Non-mutating _read on a mutable View — &self is required for pointer construction.
var insert: Property<Insert>.View {
    _read {                                     // missing `mutating`
        yield unsafe Property<Insert>.View(&self)   // error: &self needs mutating
    }
}
```

**Rationale**: Swift reserves `&self` for mutating contexts. A non-mutating
`_read` cannot take `&self`, so a `View(&self)` construction in a non-mutating
accessor won't compile. If you need non-mutating access, use `Property.View.Read`
with the borrowing-init overload — see `[PRP-009]`.

---

## Pattern: read-only access on `let`-bound `~Copyable`

### [PRP-009] `Property.View.Read` enables `let`-bound `~Copyable` callers via borrowing-init

**Statement**: For read-only access to a `~Copyable` container, use
`Property<Tag>.View.Read` (paired with the container-level
`typealias Property<Tag>` per `[PRP-003]`) with a **non-mutating** `_read`
accessor and the `init(_ base: borrowing Base)` overload. This works on
`let`-bound containers; the mutable `View` variant does not.

**Correct**:
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
    @inlinable public var count: Int { unsafe base.pointee.count }
}

// Call site — works on `let` bindings:
let container = Container()
let size = container.inspect.count
```

**Incorrect**:
```swift
// ❌ Explicit `borrowing:` label — dropped in the released API.
yield unsafe Property.View.Read(borrowing: self)
```

**Rationale**: `Property.View.Read`'s `init(_ base: borrowing Base)` obtains an
`UnsafePointer` via `withUnsafePointer(to:)` without requiring `&self`. This makes
it the only variant reachable from non-mutating `_read` accessors and from
`let`-bound `~Copyable` containers. For the mutable equivalent, the mutable
`Property.View` cannot be used in this context — `&self` is mandatory for
`UnsafeMutablePointer` construction.

---

### [PRP-010] No `borrowing:` argument label on `Property.View*` inits

**Statement**: The `Property.View*` `init(_ base: borrowing Base)` overloads MUST
be called WITHOUT the `borrowing:` argument label. Type-based overload resolution
disambiguates borrowing-init vs pointer-init.

**Correct**:
```swift
yield unsafe Property.View.Read(self)                  // borrowing init
yield unsafe Property.View.Read(pointer)               // pointer init
```

**Incorrect**:
```swift
yield unsafe Property.View.Read(borrowing: self)       // ❌ Stale API — label dropped.
```

**Rationale**: The `borrowing:` label was redundant with Swift's type-based
overload resolution and was dropped in the 0.1.0 release. Swift does not provide
an expression-form `borrowing self` syntax at call sites, so the label couldn't
offer expression-level explicitness either.

**Cross-references**: `Research/borrowing-label-drop-rationale.md` for the full
decision record.

---

## Pattern: `.verb { }` and `.verb.consuming { }` from a single accessor

### [PRP-011] Use `Property.Consuming` for binary borrow-vs-consume call sites

**Statement**: When one accessor must support BOTH `.verb { }` (borrow the
container) AND `.verb.consuming { }` (empty the container), use
`Property<Tag, Base>.Consuming<Element>` with the `borrow()` / `consume()` /
`restore()` trio in the `_modify` body.

**Correct**:
```swift
extension Container where Element: Copyable {
    public typealias Property<Tag> = Property_Primitives.Property<Tag, Self>

    public enum ForEach {}

    public var forEach: Property<ForEach>.Consuming<Element> {
        mutating _modify {
            var property = Property<ForEach>.Consuming(self)
            self = Container()
            defer {
                if let restored = property.restore() {
                    self = restored
                }
            }
            yield &property
        }
    }
}

extension Property_Primitives.Property.Consuming
where Tag == Container<Element>.ForEach, Base == Container<Element> {
    public func callAsFunction(_ body: (Element) -> Void) {
        guard let base = borrow() else { return }
        for element in base.elements { body(element) }
    }

    public mutating func consuming(_ body: (Element) -> Void) {
        guard let base = consume() else { return }
        for element in base.elements { body(element) }
    }
}

// Call sites:
container.forEach { print($0) }             // borrow — container preserved
container.forEach.consuming { process($0) } // consume — container emptied
```

**Incorrect**:
```swift
// ❌ Stale API — `borrowBase()` / `consumeBase()` are compound and were renamed.
guard let base = borrowBase() else { return }
guard let base = consumeBase() else { return }
```

**Rationale**: `Property.Consuming` tracks consumption in a reference-type `State`.
The `_modify` accessor's `defer` block queries `restore()` to decide whether to
restore `self`. The caller picks by *which method* they invoke —
`callAsFunction` (borrow) vs `consuming` (consume). Requires `Base: Copyable`;
for `~Copyable` containers, use `Property.View` with the `.consuming()` namespace-
method pattern instead.

**Note**: `isConsumed` is retained on `Property.Consuming` and on
`Property.Consuming.State` as a boolean property — this is the `is` + adjective
form explicitly permitted by `[API-NAME-002]`'s boolean-naming exception, not a
verb-noun compound.

---

## Pattern: value generics (.Valued chain)

### [PRP-012] Append `.Valued<n>` for each value generic; use the tag-enum-View typealias to shorten

**Statement**: Containers with compile-time integer generics (e.g.
`Buffer<Element>.Linked<N>.Inline<capacity>`) MUST lift each value generic to the
type level via `.Valued<n>` suffix chains. For two value generics use
`.Valued<N>.Valued<capacity>`. Use the tag-enum-`View` typealias pattern to keep
call-site verbosity manageable.

**Correct (one value generic)**:
```swift
extension Buffer.Linked where Element: ~Copyable {
    public enum Insert {
        public typealias View = Property<Insert, Buffer<Element>.Linked<N>>
            .View.Typed<Element>.Valued<N>
    }

    public var insert: Insert.View {
        mutating _read  { yield unsafe .init(&self) }
        mutating _modify {
            var view: Insert.View = unsafe .init(&self)
            yield &view
        }
    }
}

extension Property_Primitives.Property.View.Typed.Valued
where Tag == Buffer<Element>.Linked<n>.Insert, Base == Buffer<Element>.Linked<n>,
      Element: ~Copyable {
    mutating func front(_ element: consuming Element) { /* ... */ }
}
```

**Correct (two value generics)**:
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

**Incorrect**:
```swift
// ❌ Inline the full type at every accessor — verbose, error-prone.
var insert: Property<Buffer<Element>.Linked<N>.Insert,
                     Buffer<Element>.Linked<N>.Inline<capacity>>
    .View.Typed<Element>.Valued<N>.Valued<capacity>
{ ... }
```

**Rationale**: Value generics lifted to the type level (`.Valued<n>`) can appear
in extension where-clauses; method-level `where Base == Buffer<Element>.Linked<n>`
causes the compiler to add an implicit `Base: Copyable` constraint that breaks
`~Copyable` support. The tag-enum-View typealias writes the verbose chain once
(on the tag enum) and reads as `Insert.View` at every use site.

**Cross-references**: `Research/property-view-valued-verbosity.md` — V10 is the
canonical pattern (13 variants considered); buffer-primitives ships this pattern
across 333 tests.

---

## Naming rules at the call site

### [PRP-013] Avoid compound identifiers in your accessor and method names

**Statement**: Your accessor names (`var push`, `var peek`, `var inspect`) and
your method extensions on `Property*` (`func back`, `func front`, `var count`)
MUST follow `[API-NAME-002]` — no verb-noun or compound identifiers. Use nested
accessor structure where multi-word semantics are genuinely required.

**Correct**:
```swift
var push: Property<Push> { ... }               // single word
var pop: Property<Pop> { ... }
var peek: Property<Peek>.Typed<Element> { ... }
var merge: Property<Merge>.Typed<Element> { ... }

extension Property where Tag == Stack<E>.Push {
    mutating func back(_ element: E) { ... }    // single word
}

extension Property.Typed where Tag == Stack<E>.Peek {
    var back: E?  { ... }
    var count: Int { ... }
    var isEmpty: Bool { ... }                   // boolean exception: `is` + adjective is single-concept
}
```

**Incorrect**:
```swift
// ❌ Compound method names.
var pushBack: ...   // should be `push.back` or `push { .back }`
mutating func popFront()
mutating func removeLast()

// ❌ Compound type names.
struct InlineStack<Element> { ... }             // should be `Stack.Inline<Element>`
```

**Rationale**: The ecosystem's `[API-NAME-001]` (Nest.Name) and `[API-NAME-002]`
(no compound identifiers) rules apply to consumer code defining Property accessor
surfaces, not just to the `swift-property-primitives` package itself. A consumer
shipping `container.pushBack(x)` teaches the wrong convention even if
`Property.back` is clean. The `is` + adjective boolean form (`isEmpty`,
`isConsumed`, `isFinished`) is explicitly permitted.

**Cross-references**: `[API-NAME-001]`, `[API-NAME-002]` in the `code-surface`
skill.

---

## Cross-References

- **Foundational paper**: `Research/property-type-family.md` — three-category
  accessor taxonomy, phantom type pattern, protocol-conformance investigation
  (status: DECISION).
- **Dictionary migration case**: `Research/case-study-dictionary-primitives-migration-failure.md`
  — where the pattern does NOT fit (two generic parameters, protocol conformance,
  doubly-nested accessor chains).
- **`~Escapable` history**: `Research/property-view-escapable-removal.md` — the
  decision record behind the mutable-View / Read-View split (status: DECISION).
- **Value-generic verbosity**: `Research/property-view-valued-verbosity.md` — full
  trade-off analysis of the `.Valued.Valued` chain and the tag-enum-View pattern
  (status: DECISION).
- **DocC catalogues**: each variant target ships a `.docc` catalogue at
  `Sources/{Module}.docc/` with per-type articles — read these for long-form
  rationale and additional worked examples.
- **Migration instruction**: `Research/migration-instruction.md` — step-by-step
  process if you're converting an existing bespoke proxy struct to the Property
  pattern (status: IMPLEMENTED).

---

## Skill History

- 2026-01-21: `[PRP-001]` established (unified Property type family).
- 2026-04-20: Expanded to cover the variant decomposition landing in the first
  public release (package-maintainer facing).
- 2026-04-21: Rewritten as a consumer-facing skill — decision tree + canonical
  patterns + naming rules. Internal structure (target shape, namespace anchors,
  `deferred/inlined` branch status) moved to the variant-decomposition-rationale
  research doc where it belongs.
