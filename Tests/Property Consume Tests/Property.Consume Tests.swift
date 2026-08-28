import Property_Consume
import Property_Test_Support
import Testing

private typealias _ConsumeIsSendable = Require.Sendable<Property::Property<Phantom, Int>.Consume<Int>>

final class NonSendableElement {
    var value: Int

    init(_ value: Int) {
        self.value = value
    }
}

@Suite
struct `Property.Consume Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.Consume Tests`.Unit {

    @Test
    func `borrow returns base when not consumed`() {
        let consume = Property::Property<Phantom, Int>.Consume<Int>(42)
        let borrowed = consume.borrow()
        let consumed = consume.isConsumed

        #expect(borrowed == 42)
        #expect(!consumed)
    }

    @Test
    func `consume transfers ownership and marks consumed`() {
        var consume = Property::Property<Phantom, Int>.Consume<Int>(42)
        let taken = consume.consume()
        let consumed = consume.isConsumed
        let borrowed = consume.borrow()

        #expect(taken == 42)
        #expect(consumed)
        #expect(borrowed == nil)
    }

    @Test
    func `restore returns base when not consumed`() {
        let consume = Property::Property<Phantom, Int>.Consume<Int>(42)
        let restored = consume.restore()

        #expect(restored == 42)
    }

    @Test
    func `restore returns nil after consume`() {
        var consume = Property::Property<Phantom, Int>.Consume<Int>(42)
        let taken = consume.consume()
        let restored = consume.restore()

        #expect(taken == 42)
        #expect(restored == nil)
    }

    @Test
    func `double consume returns nil on second call`() {
        var consume = Property::Property<Phantom, Int>.Consume<Int>(77)

        let first = consume.consume()
        let second = consume.consume()

        #expect(first == 77)
        #expect(second == nil)
    }

    @Test
    func `init from state wraps existing state`() {
        let state = Property::Property<Phantom, Int>.Consume<Int>.State(11)
        let consume = Property::Property<Phantom, Int>.Consume<Int>(state: state)

        let borrowed = consume.borrow()
        let consumed = consume.isConsumed

        #expect(borrowed == 11)
        #expect(!consumed)
    }

    @Test
    func `state getter returns the wrapped State instance`() {
        let state = Property::Property<Phantom, Int>.Consume<Int>.State(22)
        let consume = Property::Property<Phantom, Int>.Consume<Int>(state: state)

        #expect(consume.state === state)
    }
}

extension `Property.Consume Tests`.`Edge Case` {

    @Test
    func `restore is idempotent on non-consumed state`() {
        let consume = Property::Property<Phantom, Int>.Consume<Int>(33)

        let first = consume.restore()
        let second = consume.restore()
        let third = consume.restore()
        let consumed = consume.isConsumed

        #expect(first == 33)
        #expect(second == 33)
        #expect(third == 33)
        #expect(!consumed)
    }

    @Test
    func `isConsumed is sticky after consume + borrow sequence`() {
        var consume = Property::Property<Phantom, Int>.Consume<Int>(55)

        _ = consume.consume()
        _ = consume.borrow()
        let stillConsumed = consume.isConsumed

        _ = consume.borrow()
        let consumedAfterSecondBorrow = consume.isConsumed

        #expect(stillConsumed)
        #expect(consumedAfterSecondBorrow)
    }
}

extension `Property.Consume Tests`.Integration {

    @Test
    func `borrow path via accessor preserves container`() {
        let container = Container(1, 2, 3)

        var collected: [Int] = []
        container.forEach { collected.append($0) }

        #expect(collected == [1, 2, 3])
        #expect(container.count == 3)
    }

    @Test
    func `consume path via accessor empties container`() {
        var container = Container(10, 20, 30)

        var collected: [Int] = []
        container.forEach.consuming { collected.append($0) }

        #expect(collected == [10, 20, 30])
        #expect(container.isEmpty)
    }

    @Test
    func `borrow path is idempotent across multiple calls`() {
        let container = Container(5, 6)

        var firstPass: [Int] = []
        container.forEach { firstPass.append($0) }

        var secondPass: [Int] = []
        container.forEach { secondPass.append($0) }

        #expect(firstPass == [5, 6])
        #expect(secondPass == [5, 6])
        #expect(container.count == 2)
    }

    @Test
    func `borrow path via accessor works for a non-Sendable Base`() {
        let container = Container(NonSendableElement(1), NonSendableElement(2))

        var collected: [Int] = []
        container.forEach { collected.append($0.value) }
        let remaining = container.count

        #expect(collected == [1, 2])
        #expect(remaining == 2)
    }

    @Test
    func `consume path via accessor works for a non-Sendable Base`() {
        var container = Container(NonSendableElement(3), NonSendableElement(4))

        var collected: [Int] = []
        container.forEach.consuming { collected.append($0.value) }
        let emptied = container.isEmpty

        #expect(collected == [3, 4])
        #expect(emptied)
    }

    @Test
    func `consume path leaves container reusable`() {
        var container = Container(7, 8, 9)

        container.forEach.consuming { _ in }
        #expect(container.isEmpty)

        container.push.back(100)
        container.push.back(200)
        #expect(container.count == 2)

        var refilled: [Int] = []
        container.forEach { refilled.append($0) }
        #expect(refilled == [100, 200])
    }
}
