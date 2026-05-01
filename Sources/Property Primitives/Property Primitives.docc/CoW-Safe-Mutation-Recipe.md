# The CoW-Safe Mutation Recipe

@Metadata {
    @TitleHeading("Swift Primitives")
}

A `_modify` accessor that yields a ``Property`` follows a five-step recipe.
The ordering is load-bearing — a wrong order silently defeats copy-on-write
and mutates shared storage.

## The recipe

```swift
extension Stack {
    public var push: Property<Push> {
        _read { yield Property<Push>(self) }      // Non-mutating read path.
        _modify {
            makeUnique()                          // 1. Force uniqueness
            reserve(count + 1)                    // 2. Pre-allocate if needed
            var property: Property<Push> = .init(self)
            self = Stack()                        // 3. Clear self
            defer { self = property.base }        // 4. Restore on exit
            yield &property                       // 5. Yield for mutation
        }
    }
}
```

`_modify` must be paired with `_read` (or `get`). The `_read` path yields a
by-value copy of the property, used when callers access through a non-mutating
reference. The `_modify` path is where the CoW-safe recipe lives; its five
steps are what follow.

Each step has a specific job. Skipping or reordering any of them creates a
bug that may not manifest until the caller shares the container across
references.

## Step 1 — Force uniqueness BEFORE transfer

```swift
makeUnique()
```

`isKnownUniquelyReferenced` on the underlying storage must be true *before*
the container is transferred into the property proxy. If two outer references
shared the storage, mutations through the proxy would mutate the shared
buffer — breaking value semantics.

`makeUnique()` is the container's own method that consults
`isKnownUniquelyReferenced` and copies the storage if needed. After this line,
`self` holds a uniquely-owned buffer.

**Why it must come first.** If uniqueness is checked *after* step 3
(`self = Stack()`), the check sees a freshly-constructed empty container (which
is always uniquely referenced) — a false positive that hides the original
sharing.

## Step 2 — Pre-allocate if needed

```swift
reserve(count + 1)
```

Any mutation that grows the container (push, insert) should pre-allocate
before the transfer. After the transfer, calling `reserve` would allocate on
the proxy's copy of the storage; the caller's original reference would still
see the old capacity when restored.

This step is container-specific: `push` pre-allocates one slot, `insert(n:)`
pre-allocates n slots, and read-only operations (`peek`) can skip it.

## Step 3 — Transfer the base and clear self

```swift
var property: Property<Push> = .init(self)
self = Stack()
```

The proxy takes ownership of the container via its `init(_ base: consuming Base)`.
Immediately after, `self = Stack()` releases the caller's reference to the
storage so that the proxy is the sole owner during the yield.

**Why `self = Stack()` is load-bearing.** Without it, both `self` and
`property` would hold references to the same (now-unique) storage buffer.
The proxy's uniqueness check — if it ran one inside an extension — would
return false, defeating in-place mutation.

The temporary `Stack()` is always cheap: it's a stock empty container. The
caller never observes it because control has already yielded to the closure.

## Step 4 — Restore on scope exit

```swift
defer { self = property.base }
```

When the `_modify` body exits (normal return, thrown error, or early exit),
the `defer` assigns the (possibly-mutated) base back to `self`. This is how
mutations performed through the proxy reach the caller.

**Why `defer`.** The `yield` in step 5 is a suspension point — control passes
to the caller's closure. Whatever path the closure takes (return, throw,
break), the `defer` fires on the way out. Without `defer`, a throwing closure
would lose the proxy's mutations.

## Step 5 — Yield for mutation

```swift
yield &property
```

Control passes to the caller's closure; the closure mutates `property`
through extensions on ``Property``. On scope exit, control resumes after the
`yield`, the `defer` fires, and `self` receives the mutated base.

## What happens if you reorder

| Misordering | Bug |
|-------------|-----|
| Make unique AFTER clear self | Uniqueness check always passes (empty container is always unique); real sharing is hidden. |
| Clear self BEFORE transfer | Proxy never receives the base value; accessor body sees `Stack()`. |
| Pre-allocate AFTER transfer | Proxy's buffer grows, caller's restored buffer has the old capacity. |
| Restore without `defer` | Thrown closures lose the mutation. |
| No clear self | Both `self` and `property` reference the same buffer; proxy's uniqueness check fails. |

## What this applies to

The recipe applies to accessors on ``Property`` (method-case) and
``Property/Typed`` (property-case) when the base is `Copyable`. For
``Property/Consuming`` the recipe is similar but adds a `restore()` query in
the `defer` to conditionally restore — see the canonical example in
``Property/Consuming``.

For `~Copyable` bases the recipe is different: ``Property/View-swift.struct``
uses `mutating _read` / `_modify` with an `UnsafeMutablePointer<Base>`, and
there is no transfer. The uniqueness and pre-allocation concerns don't apply —
`~Copyable` storage is always uniquely owned by definition. See
<doc:~Copyable-Base-Patterns>.

## See Also

- ``Property``
- ``Property/Typed``
- ``Property/Consuming``
- <doc:GettingStarted>
- <doc:Choosing-A-Property-Variant>
- <doc:~Copyable-Base-Patterns>
