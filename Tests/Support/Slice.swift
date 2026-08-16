public struct Slice<Element: ~Copyable>: ~Copyable {
    public var count: Int

    // Slice is a test fixture; bare-Int `count` is the fixture's domain
    // sample, not a typed-boundary surface (would be Cardinal in real API).
    // swift-linter:disable:next int public parameter
    public init(count: Int) {
        self.count = count
    }
}

extension Slice where Element: ~Copyable {
    public enum Peek {}
    public enum Borrow {}
    public enum Access {}
}

extension Slice where Element: ~Copyable {
    public var peek: Property<Peek, Slice<Element>>.Borrow.Typed<Element> {
        _read {
            yield Property<Peek, Slice<Element>>.Borrow.Typed(self)
        }
    }

    public var borrow: Property<Borrow, Slice<Element>>.Borrow.Typed<Element> {
        _read {
            yield Property<Borrow, Slice<Element>>.Borrow.Typed(self)
        }
    }

    public var access: Property<Access, Slice<Element>>.Inout.Typed<Element> {
        mutating _read {
            yield Property<Access, Slice<Element>>.Inout.Typed<Element>(&self)
        }
        mutating _modify {
            var accessor = Property<Access, Slice<Element>>.Inout.Typed<Element>(&self)
            yield &accessor
        }
    }
}

extension Property.Borrow.Typed where Tag == Slice<Int>.Peek, Base == Slice<Int> {
    public var size: Int {
        self.base.value.count
    }
}

extension Property.Borrow.Typed where Tag == Slice<Int>.Borrow, Base == Slice<Int> {
    public var size: Int {
        self.base.value.count
    }
}

extension Property.Inout.Typed where Tag == Slice<Int>.Access, Base == Slice<Int>, Element == Int {
    public var size: Int {
        self.base.value.count
    }

    // Fixture's Int newCount mirrors Slice's Int count — both are scaffolding.
    // swift-linter:disable:next int public parameter
    public mutating func resize(to newCount: Int) {
        self.base.value.count = newCount
    }
}

extension Property.Inout.Typed where Tag == Slice<Int>.Access, Base == Slice<Int>, Element == Int {
    /// Removes one element — written through the view.
    public mutating func removeOne() {
        self.base.value.count -= 1
    }
}

extension Property.Borrow.Typed where Tag == Slice<Int>.Peek, Base == Slice<Int> {
    /// Whether the slice holds no elements — read through the borrow view.
    public var isEmpty: Bool {
        self.base.value.count == 0
    }
}

extension Slice where Element == Int {
    /// Drains `self` one element at a time, reading the condition through the
    /// borrow view and mutating through the inout view. Returns the trip count.
    @inlinable
    public mutating func drainAll() -> Int {
        var trips = 0
        while !self.peek.isEmpty {
            self.access.removeOne()
            trips += 1
            if trips > 100 { break }
        }
        return trips
    }
}
