import Property_Primitives_Test_Support
import Testing

// MARK: - Type-level admission of ~Escapable Base
//
// If `Property.Borrow.Typed` regresses to require `Base: Escapable`, the
// admission test below fails to compile.

@Suite
struct `Property.Borrow.Typed Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.Borrow.Typed Tests`.Unit {

    /// Compile-time admission: the new `init(unsafeRawAddress:borrowing:)` is
    /// only available when `Base: ~Copyable & ~Escapable`.
    @Test
    func `Property.Borrow.Typed~Escapable type-level admission via init(unsafeRawAddress:borrowing:)`() {
        // Closure exists for compile-time admission — never invoked.
        let _ = { (storage: UnsafeRawPointer, owner: borrowing Int) in
            _ = unsafe Property<NEResource.Inspect, NEResource>.Borrow.Typed<Int>(
                unsafeRawAddress: storage,
                borrowing: owner
            )
        }
        #expect(true)
    }
}

extension `Property.Borrow.Typed Tests`.Unit {

    @Test
    func `borrow typed basic usage`() {
        var slice = Slice<Int>(count: 5)

        #expect(slice.peek.size == 5)
    }

    @Test
    func `borrowing typed init with let binding`() {
        let slice = Slice<Int>(count: 7)

        #expect(slice.borrow.size == 7)
    }
}
