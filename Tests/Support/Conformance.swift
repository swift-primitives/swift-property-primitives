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

extension Require {
    /// Overload-resolution assertion of whether `T` is `Sendable`, in either
    /// direction.
    ///
    /// `Require.Sendable<T>` above only ever *compiles*: instantiating it
    /// forces the positive check (`T: Sendable`) but has no way to assert the
    /// negative — there is no `Require.NotSendable<T>` that fails to compile
    /// when `T` unexpectedly gains `Sendable`. `isSendable` closes that gap by
    /// deciding the question at compile time via overload resolution instead
    /// of via conformance-checking a generic parameter:
    ///
    /// - The unconstrained overload accepts any `~Copyable` `T`.
    /// - The `Sendable`-constrained overload is strictly more specific and
    ///   is preferred whenever it applies.
    ///
    /// So a `Sendable` `T` resolves to the second overload (`true`), and a
    /// non-Sendable `T` — for which the second overload isn't a candidate at
    /// all — falls back to the first (`false`). Both branches type-check
    /// unconditionally; only the selected overload's body runs, so this is
    /// exact, not a runtime approximation.
    ///
    /// Use it to assert a conditional `@unchecked Sendable` conformance's
    /// `where` clause both ways — that it holds when the constraint is met,
    /// and that it does *not* silently widen when the constraint is not:
    ///
    /// ```swift
    /// #expect(Require.isSendable(Property<Phantom, Int>.Consume<Int>.State.self) == true)
    /// #expect(Require.isSendable(Property<Phantom, NonSendableElement>.Consume<Int>.State.self) == false)
    /// ```
    public static func isSendable<T: ~Swift.Copyable>(_: T.Type) -> Bool { false }
    public static func isSendable<T: ~Swift.Copyable & Swift.Sendable>(_: T.Type) -> Bool { true }
}
