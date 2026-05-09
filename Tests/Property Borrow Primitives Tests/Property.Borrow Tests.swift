import Property_Primitives_Test_Support
import Testing

// MARK: - Type-level admission of ~Escapable Base
//
// If `Property.Borrow` regresses to require `Base: Escapable`, this typealias
// fails to compile. NEResource is `~Copyable & ~Escapable` per the cohort's
// canonical fixture pattern.
private typealias _BorrowAdmitsNEResource = Property<NEResource.Inspect, NEResource>.Borrow
private typealias _BorrowTypedAdmitsNEResource = Property<NEResource.Inspect, NEResource>.Borrow.Typed<Int>

@Suite
struct `Property.Borrow Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.Borrow Tests`.Unit {

    @Test
    func `borrow accessor basic usage`() {
        var box = Box(value: 42)

        #expect(box.inspect.current == 42)
        #expect(box.inspect.first == 1)
    }

    @Test
    func `borrowing init with let binding`() {
        let box = Box(value: 42)

        #expect(box.borrow.current == 42)
        #expect(box.borrow.first == 1)
    }
}

extension `Property.Borrow Tests`.Unit {

    /// Compile-time admission: the new `init(unsafeRawAddress:borrowing:)` is
    /// only available when `Base: ~Copyable & ~Escapable`. The Borrow path
    /// is compile-time-admission only in this dispatch — runtime call-site
    /// pattern for non-mutating `_read` on `~Escapable Self` deferred until
    /// a consumer surfaces. Mirrors `swift-ownership-primitives`'
    /// `Ownership.Borrow` admission test shape.
    @Test
    func `Property.Borrow~Escapable type-level admission via init(unsafeRawAddress:borrowing:)`() {
        // Closure exists for compile-time admission — never invoked.
        let _ = { (storage: UnsafeRawPointer, owner: borrowing Int) in
            _ = unsafe Property<NEResource.Inspect, NEResource>.Borrow(
                unsafeRawAddress: storage,
                borrowing: owner
            )
        }
        #expect(true)
    }
}

extension `Property.Borrow Tests`.`Edge Case` {

    @Test
    func `borrow accessor does not mutate`() {
        var box = Box(value: 100)

        let first = box.inspect.current
        let second = box.inspect.current

        #expect(first == 100)
        #expect(second == 100)
    }

    @Test
    func `borrowing init supports multiple reads`() {
        let box = Box(value: 100)

        let first = box.borrow.current
        let second = box.borrow.current

        #expect(first == 100)
        #expect(second == 100)
    }
}
