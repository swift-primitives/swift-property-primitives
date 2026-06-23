# Property Primitives Scope

`swift-property-primitives` provides the **fluent-accessor property type family** —
`value.namespace.method(_:)` for any base type, without a bespoke proxy struct per
namespace. It owns the layer-invariant `Property<Tag, Base>` namespace wrapper and
the variant surface that extends it along two axes — ownership mode (`Copyable` vs
`~Copyable`) and extension shape (method-case, property-case, read-only, consuming,
value-generic).

## Per-[MOD-031] shape

The package follows `[MOD-031]` per-sub-namespace decomposition: `Property Primitive`
is the layer-invariant namespace target per `[MOD-017]`, and each variant /
cross-cutting concern is its own target. There is no `Property Primitives Core`
target — the legacy `[MOD-001]` Core convention is deprecated and was retired from
this package during the L1 core-dissolution sweep (2026-06-23). Because that Core was
internal-only (never a published product), it was deleted outright with no
transitional shim.

## Owner targets

- **Property Primitive** — the `public struct Property<Tag: ~Copyable & ~Escapable,
  Base: ~Copyable>: ~Copyable` namespace wrapper. Zero external deps per `[MOD-017]`'s
  invariant.
- **Property Carrier Primitives** — the `Property: Carrier.\`Protocol\`` conformance
  (the Q2/Q4 `~Copyable` sibling to `Tagged: Carrier.\`Protocol\``). Carries the
  external `Carrier Primitives` dependency, so it is a sub-namespace target, not root
  content, per `[MOD-017]`.
- **Property Typed Primitives** — `Property<Tag, Base>.Typed<Element>`, the
  property-case variant that smuggles `Element` into scope for `var` extensions.
- **Property Consume Primitives** — `Property<Tag, Base>.Consume<Element>`, the
  binary borrow-vs-consume variant for `Copyable` bases.
- **Property Inout Primitives** — `Property<Tag, Base>.Inout` family (mutable pointer
  access on `~Copyable` bases). Carries `Ownership Inout Primitives` + `Tagged
  Primitives`.
- **Property Borrow Primitives** — `Property<Tag, Base>.Borrow` family (read-only
  pointer access; supports `let`-bound `~Copyable`). Carries `Ownership Borrow
  Primitives` + `Tagged Primitives`.
- **Property Primitives** — umbrella; re-exports the root + every variant /
  sub-namespace target so consumers needing the union write `import
  Property_Primitives`.
- **Property Primitives Test Support** — published test-fixtures product.

## Out of scope

- **Concrete container accessors** (`stack.push.back`, `deque.peek.front`) — declared
  by the consuming container package, not here. This package supplies only the
  `Property` substrate the accessors are built on.
- **`Tagged<Tag, Underlying>`** — the Q1/Q3 `Copyable` sibling in the Carrier family
  lives in `swift-tagged-primitives`.

## Evaluation rule

Sub-target additions are evaluated against this scope.

- A proposed addition that is a **new way to extend `Property`** along the ownership ×
  extension-shape axes (a new variant) lands as its own variant target per `[MOD-031]`.
- A proposed addition that is **zero-dep namespace substrate** lands in `Property
  Primitive`; one that **carries an external dependency** lands in / as a dedicated
  sub-namespace target that declares that dependency itself per `[MOD-017]`.
- A proposed addition that is a **concrete container accessor surface** belongs in the
  consuming container's package, not here.
