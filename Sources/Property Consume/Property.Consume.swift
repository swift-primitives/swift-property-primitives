public import Property

extension Property::Property where Base: Copyable {

    public struct Consume<Element>: ~Copyable {
        @usableFromInline
        internal let _state: State

        @inlinable
        public init(_ base: consuming Base) {
            self._state = State(base)
        }

        @inlinable
        public init(state: State) {
            self._state = state
        }
    }
}

extension Property::Property.Consume {

    @inlinable
    public var state: State { _state }

    @inlinable
    public var isConsumed: Bool { _state.isConsumed }
}

extension Property::Property.Consume {

    @inlinable
    public func borrow() -> Base? {
        _state.borrow()
    }
}

extension Property::Property.Consume {

    @inlinable
    public mutating func consume() -> Base? {
        _state.consume()
    }
}

extension Property::Property.Consume {

    @inlinable
    public func restore() -> Base? {
        _state.restore()
    }
}

extension Property::Property.Consume: Sendable where Base: Sendable {}
