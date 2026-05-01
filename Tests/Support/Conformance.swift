/// Compile-time constraint holders for asserting conditional conformances.
///
/// Instantiating one of these enums at file scope (typically via a private
/// typealias) forces the compiler to check the constraint. If the check
/// fails, the module fails to build — catching conformance regressions that
/// runtime tests cannot.
///
/// Usage:
/// ```swift
/// private typealias _PropertyIsCopyable = RequireCopyable<Property<Phantom, Int>>
/// private typealias _PropertyIsSendable = RequireSendable<Property<Phantom, Int>>
/// ```
///
/// `RequireSendable` suppresses the default Copyable constraint on `T` so it
/// accepts both Copyable and `~Copyable` types (e.g., `Property.Consuming`).
///
/// Uninhabited enums — zero runtime cost.

public enum RequireCopyable<T: Copyable> {}

public enum RequireSendable<T: ~Copyable & Sendable> {}
