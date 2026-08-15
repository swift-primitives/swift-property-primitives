import Dispatch
import Property_Primitives_Test_Support
import Synchronization
import Testing

// MARK: - Compile-time conformance assertions
//
// State is @unchecked Sendable only where Base: Sendable — the clause is
// load-bearing (see the SAFETY note on the conformance). This asserts the
// Sendable case. `Property.Consume Tests.swift` separately exercises the
// accessor pattern over a non-Sendable Base at runtime, but until the negative
// assertion just below, nothing asserted the *conformance* case — that State
// stays non-Sendable when Base is not — at compile time.

private typealias _StateIsSendable = Require.Sendable<Property<Phantom, Int>.Consume<Int>.State>

// MARK: - #7: the `where Base: Sendable` clause must never silently widen
//
// `_StateIsSendable` above only ever asserts the positive direction — that
// `State` *is* `Sendable` when `Base` is. It cannot express the negative:
// nothing failed to compile before this test if a future edit widened the
// `where` clause (or dropped it) so that `State` became unconditionally
// `Sendable`. `Require.isSendable` closes that gap via overload resolution
// (see its doc comment in `Tests/Support/Conformance.swift`), so both
// directions are checked here. Reuses `NonSendableElement` from
// `Property.Consume Tests.swift` — do not retire that guard (see the #4 note
// there); do not make it `Sendable`, or this test stops meaning anything.
//
// This is fact 1 of the three-fact conjunction in the SAFETY note on
// `Property.Consume.State`'s conditional `Sendable` conformance. Facts 2 (no
// `sending`-typed public return whose type mentions `Base`) and 3 (`Storage`'s
// internal single-use `@unchecked Sendable`) are not independently testable
// here — fact 2 is enforced by a swift-linter rule filed at
// swift-foundations/swift-institute-linter-rules#29, and fact 3 is a
// structural property of this file, not a conformance.

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

// MARK: - #7 negative control: the `sending`-return shape this type must never take
//
// This is fact 2 of the SAFETY conjunction and is NOT exercised by a runtime test —
// `sending` on a return is source-compatible, so no existing or addable #expect can
// distinguish "compiles and is safe" from "compiles and races." The only mechanical
// check is at the type-checker/SIL level, which is why the accepted #7 recommendation
// routes enforcement to a swift-linter rule
// (swift-foundations/swift-institute-linter-rules#29) rather than a package-local
// fixture. This repository's testing conventions have no "must fail to compile"
// fixture harness (no trybuild-style support target), so — per the #7 recommendation's
// fallback — this is left as a commented, referenced control for the linter/CI to
// check against, rather than invented ad hoc here.
//
// Reproduced from the #7 recommendation comment, standalone probe, Swift 6.4
// (swiftlang-6.4.0.27.1), `swiftc -emit-sil -swift-version 6` (region-isolation
// diagnostics require SIL emission; `-typecheck` alone reports this clean and is not
// evidence). Against a non-Sendable `Base` (`final class NS { var x = 0 }`):
//
// ```swift
// // MUST NOT COMPILE. If this starts compiling clean, fact 2 has been violated
// // somewhere in State's public surface (a `sending`-typed return whose type
// // mentions `Base` was introduced) and the linter rule above should have caught
// // it first.
// func f(_ s: Property<Phantom, NS>.Consume<Int>.State) -> sending NS? {
//     s.borrow()
// }
// // error: task or actor-isolated value cannot be sent
// ```
//
// Do not uncomment this into a real, always-passing test: `borrow()` returning a
// plain `Base?` makes the snippet fail to compile today, which means it cannot live
// as executable Swift in this file without breaking the build — it documents the
// guard, it does not exercise it. If swift-linter rule #29 lands with its own
// compile-fail fixture mechanism, migrate this control there instead of duplicating it.

extension `Property.Consume.State Tests`.`Edge Case` {

    @Test
    func
        `concurrent consume never exposes a torn consumed-and-base state to a sibling sharing State`()
    {
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

    @Test
    func `State is Sendable exactly where Base is Sendable, not before and not after`() {
        #expect(Require.isSendable(Property<Phantom, Int>.Consume<Int>.State.self) == true)
        #expect(
            Require.isSendable(Property<Phantom, NonSendableElement>.Consume<Int>.State.self)
                == false
        )
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
