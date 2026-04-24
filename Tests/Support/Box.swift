
public struct Box: ~Copyable {
    public var value: Int
    public var storage: (Int, Int, Int, Int)

    public init(value: Int) {
        self.value = value
        self.storage = (1, 2, 3, 4)
    }
}

extension Box {
    public enum Inspect {}
    public enum Borrow {}
}

extension Box {
    public var inspect: Property<Inspect, Box>.View.Read {
        _read {
            yield Property<Inspect, Box>.View.Read(self)
        }
    }

    public var borrow: Property<Borrow, Box>.View.Read {
        _read {
            yield Property<Borrow, Box>.View.Read(self)
        }
    }
}

extension Property.View.Read where Tag == Box.Inspect, Base == Box {
    public var current: Int {
        self.base.value.value
    }

    public var first: Int {
        self.base.value.storage.0
    }
}

extension Property.View.Read where Tag == Box.Borrow, Base == Box {
    public var current: Int {
        self.base.value.value
    }

    public var first: Int {
        self.base.value.storage.0
    }
}
