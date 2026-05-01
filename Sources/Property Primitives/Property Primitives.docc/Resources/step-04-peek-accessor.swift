public import Property_Primitives

public struct Stack<Element: Copyable>: Copyable {
    internal var _storage: [Element]

    public init() {
        self._storage = []
    }
}

extension Stack {
    public typealias Property<Tag> =
        Property_Primitives.Property<Tag, Stack<Element>>
}

extension Stack {
    public enum Push {}

    public var push: Property<Push> {
        _read { yield Property<Push>(self) }
        _modify {
            var property: Property<Push> = .init(self)
            self = Stack()
            defer { self = property.base }
            yield &property
        }
    }
}

extension Stack {
    public enum Peek {}

    public var peek: Property<Peek>.Typed<Element> {
        Property<Peek>.Typed(self)
    }
}

extension Property {
    public mutating func back<E>(_ element: E)
    where Tag == Stack<E>.Push, Base == Stack<E> {
        base._storage.append(element)
    }
}

extension Property.Typed
where Tag == Stack<Element>.Peek, Base == Stack<Element> {
    public var back: Element?  { base._storage.last }
    public var count: Int      { base._storage.count }
}
