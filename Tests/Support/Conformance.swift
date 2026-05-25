/// Compile-time constraint holders for asserting conditional conformances.
///
/// Instantiating one of these enums at file scope (typically via a private
/// typealias) forces the compiler to check the constraint. If the check
/// fails, the module fails to build — catching conformance regressions that
/// runtime tests cannot.
///
/// Usage:
/// ```swift
/// private typealias _PropertyIsCopyable = Require.Copyable<Property<Phantom, Int>>
/// private typealias _PropertyIsSendable = Require.Sendable<Property<Phantom, Int>>
/// ```
///
/// `Require.Sendable` suppresses the default Copyable constraint on `T` so it
/// accepts both Copyable and `~Copyable` types (e.g., `Property.Consume`).
///
/// Uninhabited enums — zero runtime cost.

public enum Require {}

extension Require {
    public enum Copyable<T: Swift.Copyable> {}

    public enum Sendable<T: ~Swift.Copyable & Swift.Sendable> {}
}
