
extension Slice.Inline where Element: ~Copyable {
    public struct Inner<let m: Int>: ~Copyable {
        public var count: Int
        public init(count: Int) { self.count = count }
    }
}

extension Slice.Inline.Inner where Element: ~Copyable {
    public enum Access {}
}

extension Slice.Inline.Inner where Element: ~Copyable {
    public var access: Property<Access, Slice<Element>.Inline<n>.Inner<m>>.View.Typed<Element>.Valued<n>.Valued<m> {
        mutating _read {
            yield Property<Access, Slice<Element>.Inline<n>.Inner<m>>.View.Typed<Element>.Valued<n>.Valued<m>(&self)
        }
        mutating _modify {
            var view = Property<Access, Slice<Element>.Inline<n>.Inner<m>>.View.Typed<Element>.Valued<n>.Valued<m>(&self)
            yield &view
        }
    }
}

extension Property.View.Typed.Valued.Valued
where Tag == Slice<Int>.Inline<n>.Inner<m>.Access,
      Base == Slice<Int>.Inline<n>.Inner<m>,
      Element == Int {
    public var size: Int {
        self.base.value.count
    }

    public var outerCapacity: Int { n }
    public var innerCapacity: Int { m }

    public mutating func resize(to newCount: Int) {
        self.base.value.count = newCount
    }
}
