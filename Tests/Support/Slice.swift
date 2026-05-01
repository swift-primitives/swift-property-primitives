public struct Slice<Element: ~Copyable>: ~Copyable {
    public var count: Int

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
    public var peek: Property<Peek, Slice<Element>>.View.Read.Typed<Element> {
        _read {
            yield Property<Peek, Slice<Element>>.View.Read.Typed(self)
        }
    }

    public var borrow: Property<Borrow, Slice<Element>>.View.Read.Typed<Element> {
        _read {
            yield Property<Borrow, Slice<Element>>.View.Read.Typed(self)
        }
    }

    public var access: Property<Access, Slice<Element>>.View.Typed<Element> {
        mutating _read {
            yield Property<Access, Slice<Element>>.View.Typed<Element>(&self)
        }
        mutating _modify {
            var view = Property<Access, Slice<Element>>.View.Typed<Element>(&self)
            yield &view
        }
    }
}

extension Property.View.Read.Typed where Tag == Slice<Int>.Peek, Base == Slice<Int> {
    public var size: Int {
        self.base.value.count
    }
}

extension Property.View.Read.Typed where Tag == Slice<Int>.Borrow, Base == Slice<Int> {
    public var size: Int {
        self.base.value.count
    }
}

extension Property.View.Typed where Tag == Slice<Int>.Access, Base == Slice<Int>, Element == Int {
    public var size: Int {
        self.base.value.count
    }

    public mutating func resize(to newCount: Int) {
        self.base.value.count = newCount
    }
}
