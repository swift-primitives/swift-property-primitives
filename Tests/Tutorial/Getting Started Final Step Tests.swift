public import Property
import Testing

public struct Stack<Element: Copyable>: Copyable {
    internal var _storage: [Element]

    public init() {
        self._storage = []
    }
}

extension Stack {
    public typealias Property<Tag> =
        Property.Property<Tag, Stack<Element>>
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
    public var back: Element? { base._storage.last }
    public var count: Int { base._storage.count }
    public var isEmpty: Bool { base._storage.isEmpty }
}

@Suite
struct `Tutorial Getting Started Final Step Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Tutorial Getting Started Final Step Tests`.Unit {

    @Test
    func `push.back and peek.back / peek.count compile and work as the tutorial shows`() {
        var stack = Stack<Int>()
        stack.push.back(1)
        stack.push.back(2)

        #expect(stack.peek.back == 2)
        #expect(stack.peek.count == 2)
    }

    @Test
    func `empty stack has nil peek.back and zero peek.count`() {
        let stack = Stack<Int>()

        #expect(stack.peek.back == nil)
        #expect(stack.peek.isEmpty)
    }
}
