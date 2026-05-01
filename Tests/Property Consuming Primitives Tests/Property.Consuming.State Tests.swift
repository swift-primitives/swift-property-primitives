import Testing
import Property_Primitives_Test_Support

// MARK: - Compile-time conformance assertions
//
// State is unconditionally @unchecked Sendable.

private typealias _StateIsSendable = RequireSendable<Property<Phantom, Int>.Consuming<Int>.State>

@Suite
struct `Property.Consuming.State Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.Consuming.State Tests`.Unit {

    @Test
    func `state init stores base and starts not consumed`() {
        let state = Property<Phantom, Int>.Consuming<Int>.State(99)

        #expect(state.isConsumed == false)
        #expect(state.borrow() == 99)
    }

    @Test
    func `state borrow returns base across repeated calls`() {
        let state = Property<Phantom, Int>.Consuming<Int>.State(7)

        #expect(state.borrow() == 7)
        #expect(state.borrow() == 7)
        #expect(state.borrow() == 7)
        #expect(state.isConsumed == false)
    }
}

extension `Property.Consuming.State Tests`.Integration {

    @Test
    func `shared state reflects consumption across Consuming instances`() {
        let state = Property<Phantom, Int>.Consuming<Int>.State(50)
        let observer = Property<Phantom, Int>.Consuming<Int>(state: state)
        var consumer = Property<Phantom, Int>.Consuming<Int>(state: state)

        let beforeConsume = observer.borrow()
        #expect(beforeConsume == 50)

        let taken = consumer.consume()
        #expect(taken == 50)

        let afterConsume = observer.borrow()
        let observerConsumed = observer.isConsumed
        let stateBorrow = state.borrow()
        let stateConsumed = state.isConsumed

        #expect(afterConsume == nil)
        #expect(observerConsumed)
        #expect(stateBorrow == nil)
        #expect(stateConsumed)
    }
}
