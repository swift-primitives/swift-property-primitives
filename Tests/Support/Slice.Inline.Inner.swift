extension Slice.Inline where Element: ~Copyable {
    public struct Inner<let m: Int>: ~Copyable {
        public var count: Int
        // Fixture's Int count is scaffolding, not a typed-boundary surface.
        // swift-linter:disable:next int public parameter
        public init(count: Int) { self.count = count }
    }
}

extension Slice.Inline.Inner where Element: ~Copyable {
    public enum Access {}
}

extension Slice.Inline.Inner where Element: ~Copyable {
    public var access: Property<Access, Slice<Element>.Inline<n>.Inner<m>>.Inout.Typed<Element>.Valued<n>.Valued<m> {
        mutating _read {
            yield Property<Access, Slice<Element>.Inline<n>.Inner<m>>.Inout.Typed<Element>.Valued<n>.Valued<m>(&self)
        }
        mutating _modify {
            var accessor = Property<Access, Slice<Element>.Inline<n>.Inner<m>>.Inout.Typed<Element>.Valued<n>.Valued<m>(&self)
            yield &accessor
        }
    }
}

extension Property.Inout.Typed.Valued.Valued
where
    Tag == Slice<Int>.Inline<n>.Inner<m>.Access,
    Base == Slice<Int>.Inline<n>.Inner<m>,
    Element == Int
{
    public var size: Int {
        self.base.value.count
    }

    public var outer: Int { n }
    public var inner: Int { m }

    // Fixture's Int newCount mirrors Slice.Inline.Inner's Int count — scaffolding.
    // swift-linter:disable:next int public parameter
    public mutating func resize(to newCount: Int) {
        self.base.value.count = newCount
    }
}
