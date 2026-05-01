extension Slice where Element: ~Copyable {
    public struct Inline<let n: Int>: ~Copyable {
        public var count: Int
        public init(count: Int) { self.count = count }
    }
}

extension Slice.Inline where Element: ~Copyable {
    public enum Access {}
    public enum Inspect {}
}

extension Slice.Inline where Element: ~Copyable {
    public var access: Property<Access, Slice<Element>.Inline<n>>.View.Typed<Element>.Valued<n> {
        mutating _read {
            yield Property<Access, Slice<Element>.Inline<n>>.View.Typed<Element>.Valued<n>(&self)
        }
        mutating _modify {
            var view = Property<Access, Slice<Element>.Inline<n>>.View.Typed<Element>.Valued<n>(&self)
            yield &view
        }
    }

    public var inspect: Property<Inspect, Slice<Element>.Inline<n>>.View.Read.Typed<Element>.Valued<n> {
        mutating _read {
            yield Property<Inspect, Slice<Element>.Inline<n>>.View.Read.Typed<Element>.Valued<n>(self)
        }
    }
}

extension Property.View.Typed.Valued
where Tag == Slice<Int>.Inline<n>.Access, Base == Slice<Int>.Inline<n>, Element == Int {
    public var size: Int {
        self.base.value.count
    }

    public var capacity: Int { n }

    public mutating func resize(to newCount: Int) {
        self.base.value.count = newCount
    }
}

extension Property.View.Read.Typed.Valued
where Tag == Slice<Int>.Inline<n>.Inspect, Base == Slice<Int>.Inline<n>, Element == Int {
    public var size: Int {
        self.base.value.count
    }

    public var capacity: Int { n }
}
