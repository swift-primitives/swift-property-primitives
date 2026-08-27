public import Property

public enum Require {}

extension Require {
    public enum Copyable<T: Swift.Copyable> {}

    public enum Sendable<T: ~Swift.Copyable & Swift.Sendable> {}
}

extension Require {

    public static func isSendable<T: ~Swift.Copyable>(_: T.Type) -> Bool { false }
    public static func isSendable<T: ~Swift.Copyable & Swift.Sendable>(_: T.Type) -> Bool { true }
}
