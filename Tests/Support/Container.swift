public struct Container<Element>: Copyable where Element: Copyable {
    internal var storage: [Element]

    public init(_ elements: Element...) {
        self.storage = elements
    }

    public var count: Int {
        self.storage.count
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
    public var push: Property<Push, Container<Element>> {
        _read { yield Property(self) }
        _modify {
            var property: Property<Push, Container<Element>> = Property(self)
            self = Container()
            defer { self = property.base }
            yield &property
        }
    }

    public var pop: Property<Pop, Container<Element>> {
        _read { yield Property(self) }
        _modify {
            var property: Property<Pop, Container<Element>> = Property(self)
            self = Container()
            defer { self = property.base }
            yield &property
        }
    }

    public var merge: Property<Merge.Keep, Container<Element>> {
        _read { yield Property(self) }
        _modify {
            var property: Property<Merge.Keep, Container<Element>> = Property(self)
            self = Container()
            defer { self = property.base }
            yield &property
        }
    }
}

extension Property where Tag == Container<Int>.Push, Base == Container<Int> {
    public mutating func back(_ element: Int) {
        self.base.storage.append(element)
    }
}

extension Property where Tag == Container<Int>.Pop, Base == Container<Int> {
    public mutating func back() -> Int {
        self.base.storage.removeLast()
    }
}

extension Property where Tag == Container<Int>.Merge.Keep, Base == Container<Int> {
    // Deliberate no-op: this accessor exists to exercise the nested phantom tag
    // `Container.Merge.Keep`. The compilation IS the test.
    public mutating func from(_ other: borrowing Container<Int>) {
        _ = other.count
    }
}

extension Container where Element: Copyable {
    public var forEach: Property<ForEach, Container<Element>>.Consuming<Element> {
        _read {
            yield Property<ForEach, Container<Element>>.Consuming<Element>(self)
        }
        mutating _modify {
            var property = Property<ForEach, Container<Element>>.Consuming<Element>(self)
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

extension Property.Consuming
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
