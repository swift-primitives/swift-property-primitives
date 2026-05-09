/// Test fixture mirroring the cohort's NEResource pattern from
/// `swift-institute/Research/escapable-support-pair-either-product.md` v1.1.0.
///
/// Verifies that `Property<Tag, Base>` and its View-family types admit
/// `Base: ~Copyable & ~Escapable` at the type level. Construction is not
/// exercised — `~Escapable` Base requires raw-address inits not yet exposed
/// on `Property.Borrow` / `Property.Inout` (see `Ownership.Borrow` /
/// `Ownership.Inout`'s `init(unsafeRawAddress:borrowing:)` /
/// `init(unsafeRawAddress:mutating:)` for the analogous lower-tier shape).
public struct NEResource: ~Escapable, ~Copyable {
    public let id: Int

    @_lifetime(immortal)
    public init(_ id: Int) { self.id = id }
}

extension NEResource {
    public enum Inspect {}
    public enum Access {}
}
