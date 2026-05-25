extension Slice where Element: ~Copyable {
    public struct Inline<let n: Int>: ~Copyable {
        public var count: Int
        // Fixture's Int count is scaffolding, not a typed-boundary surface.
        // swift-linter:disable:next int public parameter
        public init(count: Int) { self.count = count }
    }
}

extension Slice.Inline where Element: ~Copyable {
    public enum Access {}
    public enum Inspect {}
}

extension Slice.Inline where Element: ~Copyable {
    public var access: Property<Access, Slice<Element>.Inline<n>>.Inout.Typed<Element>.Valued<n> {
        mutating _read {
            yield Property<Access, Slice<Element>.Inline<n>>.Inout.Typed<Element>.Valued<n>(&self)
        }
        mutating _modify {
            var accessor = Property<Access, Slice<Element>.Inline<n>>.Inout.Typed<Element>.Valued<n>(&self)
            yield &accessor
        }
    }

    public var inspect: Property<Inspect, Slice<Element>.Inline<n>>.Borrow.Typed<Element>.Valued<n> {
        mutating _read {
            yield Property<Inspect, Slice<Element>.Inline<n>>.Borrow.Typed<Element>.Valued<n>(self)
        }
    }
}

extension Property.Inout.Typed.Valued
where Tag == Slice<Int>.Inline<n>.Access, Base == Slice<Int>.Inline<n>, Element == Int {
    public var size: Int {
        self.base.value.count
    }

    public var capacity: Int { n }

    // Fixture's Int newCount mirrors Slice.Inline's Int count — scaffolding.
    // swift-linter:disable:next int public parameter
    public mutating func resize(to newCount: Int) {
        self.base.value.count = newCount
    }
}

extension Property.Borrow.Typed.Valued
where Tag == Slice<Int>.Inline<n>.Inspect, Base == Slice<Int>.Inline<n>, Element == Int {
    public var size: Int {
        self.base.value.count
    }

    public var capacity: Int { n }
}
