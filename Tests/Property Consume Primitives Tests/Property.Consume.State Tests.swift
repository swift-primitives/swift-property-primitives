import Dispatch
import Property_Primitives_Test_Support
import Synchronization
import Testing

// MARK: - Compile-time conformance assertions
//
// State is unconditionally @unchecked Sendable.

private typealias _StateIsSendable = Require.Sendable<Property<Phantom, Int>.Consume<Int>.State>

@Suite
struct `Property.Consume.State Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

// MARK: - F-003 regression: State's shared mutable fields must be synchronized
//
// Two `Consume` instances sharing one `State` via `init(state:)` must never let a
// concurrent reader (`isConsumed` / `borrow()`) observe a "torn" combination —
// `isConsumed == true` while `borrow()` still returns non-nil — which is only
// possible if the writer's consumed-flag-set and base-clear are not committed as
// one atomic unit. Runs many independent (state, readers, single writer) groups
// concurrently on real OS threads (Dispatch, not the cooperative Task pool, which
// would starve under this many busy-spinning readers) and repeats until either a
// torn observation is caught or the attempt budget is exhausted.
private func `F-003 torn-state mega-trial`(groups: Int, readerCount: Int, spin: Int) -> Bool {
    let tornObserved = Atomic<Bool>(false)
    let group = DispatchGroup()

    for _ in 0..<groups {
        let state = Property<Phantom, Int>.Consume<Int>.State(1)
        let consumerLock = Mutex(Property<Phantom, Int>.Consume<Int>(state: state))
        let readyCount = Atomic<Int>(0)

        for _ in 0..<readerCount {
            group.enter()
            DispatchQueue.global(qos: .userInteractive).async {
                _ = readyCount.wrappingAdd(1, ordering: .relaxed)
                for _ in 0..<spin {
                    let consumed = state.isConsumed
                    let base = state.borrow()
                    if consumed && base != nil {
                        tornObserved.store(true, ordering: .relaxed)
                    }
                }
                group.leave()
            }
        }

        group.enter()
        DispatchQueue.global(qos: .userInteractive).async {
            while readyCount.load(ordering: .acquiring) < readerCount {}
            consumerLock.withLock { _ = $0.consume() }
            group.leave()
        }
    }

    group.wait()
    return tornObserved.load(ordering: .relaxed)
}

extension `Property.Consume.State Tests`.`Edge Case` {

    @Test
    func `concurrent consume never exposes a torn consumed-and-base state to a sibling sharing State`() {
        var tornObservedAcrossAttempts = false
        for _ in 0..<8 {
            if `F-003 torn-state mega-trial`(groups: 200, readerCount: 4, spin: 20_000) {
                tornObservedAcrossAttempts = true
                break
            }
        }
        #expect(tornObservedAcrossAttempts == false)
    }
}

extension `Property.Consume.State Tests`.Unit {

    @Test
    func `state init stores base and starts not consumed`() {
        let state = Property<Phantom, Int>.Consume<Int>.State(99)

        #expect(state.isConsumed == false)
        #expect(state.borrow() == 99)
    }

    @Test
    func `state borrow returns base across repeated calls`() {
        let state = Property<Phantom, Int>.Consume<Int>.State(7)

        #expect(state.borrow() == 7)
        #expect(state.borrow() == 7)
        #expect(state.borrow() == 7)
        #expect(state.isConsumed == false)
    }
}

extension `Property.Consume.State Tests`.Integration {

    @Test
    func `shared state reflects consumption across Consume instances`() {
        let state = Property<Phantom, Int>.Consume<Int>.State(50)
        let observer = Property<Phantom, Int>.Consume<Int>(state: state)
        var consumer = Property<Phantom, Int>.Consume<Int>(state: state)

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
