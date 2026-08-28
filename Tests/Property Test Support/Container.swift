public struct Container<Element>: Copyable where Element: Copyable {
    internal var storage: [Element]

    public init(_ elements: Element...) {
        self.storage = elements
    }
}

extension Container {
    public var count: Int {
        self.storage.count
    }

    public var isEmpty: Bool {
        self.storage.isEmpty
    }

    public func peek() -> Element? {
        self.storage.last
    }
}

extension Container {
    public enum Push {}
    public enum Pop {}

    public enum Merge {

        public enum Keep {}
    }
    public enum ForEach {}
}

extension Container {
    public var push: Property::Property<Push, Container<Element>> {
        _read { yield Property::Property(self) }
        _modify {
            var property: Property::Property<Push, Container<Element>> = Property::Property(self)
            self = Container()
            defer { self = property.base }
            yield &property
        }
    }

    public var pop: Property::Property<Pop, Container<Element>> {
        _read { yield Property::Property(self) }
        _modify {
            var property: Property::Property<Pop, Container<Element>> = Property::Property(self)
            self = Container()
            defer { self = property.base }
            yield &property
        }
    }

    public var merge: Property::Property<Merge.Keep, Container<Element>> {
        _read { yield Property::Property(self) }
        _modify {
            var property: Property::Property<Merge.Keep, Container<Element>> = Property::Property(self)
            self = Container()
            defer { self = property.base }
            yield &property
        }
    }
}

extension Property::Property where Tag == Container<Int>.Push, Base == Container<Int> {

    public mutating func back(_ element: Int) {
        self.base.storage.append(element)
    }
}

extension Property::Property where Tag == Container<Int>.Pop, Base == Container<Int> {

    public mutating func back() -> Int {
        self.base.storage.removeLast()
    }
}

extension Property::Property where Tag == Container<Int>.Merge.Keep, Base == Container<Int> {

    public mutating func from(_ other: borrowing Container<Int>) {
        _ = other.count
    }
}

extension Container where Element: Copyable {
    public var forEach: Property::Property<ForEach, Container<Element>>.Consume<Element> {
        _read {
            yield Property::Property<ForEach, Container<Element>>.Consume<Element>(self)
        }
        mutating _modify {
            var property = Property::Property<ForEach, Container<Element>>.Consume<Element>(self)
            self = Container<Element>()
            defer {
                if let restored = property.restore() {
                    self = restored
                }
            }
            yield &property
        }
    }
}

extension Property::Property.Consume
where Tag == Container<Element>.ForEach, Base == Container<Element>, Element: Copyable {
    public func callAsFunction(_ body: (Element) -> Void) {
        guard let base = borrow() else { return }
        for element in base.storage { body(element) }
    }

    public mutating func consuming(_ body: (Element) -> Void) {
        guard let base = consume() else { return }
        for element in base.storage { body(element) }
    }
}
