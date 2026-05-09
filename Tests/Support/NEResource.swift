/// Test fixture mirroring the cohort's NEResource pattern from
/// `swift-institute/Research/escapable-support-pair-either-product.md` v1.1.0.
///
/// Verifies that `Property<Tag, Base>` and its View-family types admit
/// `Base: ~Copyable & ~Escapable` at both the type level and the
/// construction level. Type-level admission is verified by the typealiases
/// in `Property.Inout Tests.swift` / `Property.Borrow Tests.swift` etc.
/// Construction-level admission is verified by the
/// `*~Escapable type-level admission via init(unsafeRawAddress:...)`
/// tests, which mirror `swift-ownership-primitives`' admission test shape:
/// closure literals exercise the new init's signature; never invoked at
/// runtime. See `swift-property-primitives/Research/property-inout-raw-address-init.md`.
public struct NEResource: ~Escapable, ~Copyable {
    public let id: Int

    @_lifetime(immortal)
    public init(_ id: Int) { self.id = id }
}

extension NEResource {
    public enum Inspect {}
    public enum Access {}
}
