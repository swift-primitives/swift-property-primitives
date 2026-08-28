public import Property

#if !hasFeature(Embedded)
    public import Synchronization
#else

    @usableFromInline
    internal final class _UnsynchronizedBox<Value: ~Copyable>: @unchecked Sendable {
        @usableFromInline
        internal var _value: Value

        @inlinable
        internal init(_ value: consuming sending Value) {
            self._value = value
        }

        @inlinable
        internal func withLock<Result: ~Copyable, E: Swift.Error>(
            _ body: (inout sending Value) throws(E) -> sending Result
        ) throws(E) -> sending Result {
            try body(&_value)
        }
    }
#endif

extension Property::Property.Consume where Base: Copyable {

    public final class State {

        @usableFromInline
        internal struct Storage: @unchecked Sendable {
            @usableFromInline
            internal var base: Base?

            @usableFromInline
            internal var consumed: Bool

            @usableFromInline
            internal init(base: consuming Base) {
                self.base = base
                self.consumed = false
            }
        }

        #if !hasFeature(Embedded)
            @usableFromInline
            internal let _storage: Mutex<Storage>
        #else
            @usableFromInline
            internal let _storage: _UnsynchronizedBox<Storage>
        #endif

        @inlinable
        public init(_ base: consuming Base) {
            #if !hasFeature(Embedded)
                self._storage = Mutex(Storage(base: base))
            #else
                self._storage = _UnsynchronizedBox(Storage(base: base))
            #endif
        }
    }
}

extension Property::Property.Consume.State {

    @inlinable
    public var isConsumed: Bool {
        _storage.withLock { $0.consumed }
    }

    @inlinable
    public func borrow() -> Base? {
        _storage.withLock { $0.base }
    }

    @inlinable
    package func consume() -> Base? {
        _storage.withLock { storage in
            guard let base = storage.base else { return nil }
            storage.consumed = true
            storage.base = nil
            return base
        }
    }

    @inlinable
    package func restore() -> Base? {
        _storage.withLock { storage in
            storage.consumed ? nil : storage.base
        }
    }
}

extension Property::Property.Consume.State: @unchecked Sendable where Base: Sendable {}
