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
    // Merge is a phantom-tag namespace for merge-strategy variants; the
    // fixture currently exercises only Keep, but the namespace is structural
    // intent (more variants like Replace / Append can be added later).
    // swift-linter:disable:next single type namespace
    public enum Merge {
        // Test fixture: Keep lives in Merge's body deliberately to exercise
        // the nested-namespace shape `Container.Merge.Keep` as a Property tag.
        // swift-linter:disable:next minimal type body
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
    // Int is dictated by the fixture's Container<Int> substitution, not a
    // typed-boundary surface; test scaffolding exercising the Property API.
    // swift-linter:disable:next int public parameter
    public mutating func back(_ element: Int) {
        self.base.storage.append(element)
    }
}

extension Property where Tag == Container<Int>.Pop, Base == Container<Int> {
    // Int return type is dictated by the fixture's Container<Int> substitution.
    // swift-linter:disable:next int public parameter
    public mutating func back() -> Int {
        self.base.storage.removeLast()
    }
}

// Concrete-type Tag/Base substitution (Container<Int>.Merge.Keep / Container<Int>)
// locks both to Copyable types; the rule's syntactic check can't see this.
// swift-linter:disable:next extension noncopyable constraint
extension Property where Tag == Container<Int>.Merge.Keep, Base == Container<Int> {
    // Deliberate no-op: this accessor exists to exercise the nested phantom tag
    // `Container.Merge.Keep`. The compilation IS the test.
    public mutating func from(_ other: borrowing Container<Int>) {
        _ = other.count
    }
}

extension Container where Element: Copyable {
    public var forEach: Property<ForEach, Container<Element>>.Consume<Element> {
        _read {
            yield Property<ForEach, Container<Element>>.Consume<Element>(self)
        }
        mutating _modify {
            var property = Property<ForEach, Container<Element>>.Consume<Element>(self)
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

extension Property.Consume
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
