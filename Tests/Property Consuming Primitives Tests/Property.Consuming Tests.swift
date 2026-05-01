import Testing
import Property_Primitives_Test_Support

// MARK: - Compile-time conformance assertions
//
// Property.Consuming is unconditionally ~Copyable (not conditionally
// Copyable — consuming semantics require it). Only Sendable is
// conditional, so only Sendable is asserted here.

private typealias _ConsumingIsSendable = RequireSendable<Property<Phantom, Int>.Consuming<Int>>

@Suite
struct `Property.Consuming Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.Consuming Tests`.Unit {

    @Test
    func `borrow returns base when not consumed`() {
        let consuming = Property<Phantom, Int>.Consuming<Int>(42)
        let borrowed = consuming.borrow()
        let consumed = consuming.isConsumed

        #expect(borrowed == 42)
        #expect(!consumed)
    }

    @Test
    func `consume transfers ownership and marks consumed`() {
        var consuming = Property<Phantom, Int>.Consuming<Int>(42)
        let taken = consuming.consume()
        let consumed = consuming.isConsumed
        let borrowed = consuming.borrow()

        #expect(taken == 42)
        #expect(consumed)
        #expect(borrowed == nil)
    }

    @Test
    func `restore returns base when not consumed`() {
        let consuming = Property<Phantom, Int>.Consuming<Int>(42)
        let restored = consuming.restore()

        #expect(restored == 42)
    }

    @Test
    func `restore returns nil after consume`() {
        var consuming = Property<Phantom, Int>.Consuming<Int>(42)
        let taken = consuming.consume()
        let restored = consuming.restore()

        #expect(taken == 42)
        #expect(restored == nil)
    }

    @Test
    func `double consume returns nil on second call`() {
        var consuming = Property<Phantom, Int>.Consuming<Int>(77)

        let first = consuming.consume()
        let second = consuming.consume()

        #expect(first == 77)
        #expect(second == nil)
    }

    @Test
    func `init from state wraps existing state`() {
        let state = Property<Phantom, Int>.Consuming<Int>.State(11)
        let consuming = Property<Phantom, Int>.Consuming<Int>(state: state)

        let borrowed = consuming.borrow()
        let consumed = consuming.isConsumed

        #expect(borrowed == 11)
        #expect(!consumed)
    }

    @Test
    func `state getter returns the wrapped State instance`() {
        let state = Property<Phantom, Int>.Consuming<Int>.State(22)
        let consuming = Property<Phantom, Int>.Consuming<Int>(state: state)

        #expect(consuming.state === state)
    }
}

extension `Property.Consuming Tests`.`Edge Case` {

    @Test
    func `restore is idempotent on non-consumed state`() {
        let consuming = Property<Phantom, Int>.Consuming<Int>(33)

        let first = consuming.restore()
        let second = consuming.restore()
        let third = consuming.restore()
        let consumed = consuming.isConsumed

        #expect(first == 33)
        #expect(second == 33)
        #expect(third == 33)
        #expect(!consumed)
    }

    @Test
    func `isConsumed is sticky after consume + borrow sequence`() {
        var consuming = Property<Phantom, Int>.Consuming<Int>(55)

        _ = consuming.consume()
        _ = consuming.borrow()
        let stillConsumed = consuming.isConsumed

        _ = consuming.borrow()
        let consumedAfterSecondBorrow = consuming.isConsumed

        #expect(stillConsumed)
        #expect(consumedAfterSecondBorrow)
    }
}

extension `Property.Consuming Tests`.Integration {

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
