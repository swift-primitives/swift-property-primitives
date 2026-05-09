import Property_Primitives_Test_Support
import Testing

// MARK: - Type-level admission of ~Escapable Base
//
// If `Property.Inout.Typed.Valued` regresses to require `Base: Escapable`,
// this typealias fails to compile.
private typealias _ValuedAdmitsNEResource = Property<NEResource.Access, NEResource>.Inout.Typed<Int>.Valued<3>

@Suite
struct `Property.Inout.Typed.Valued Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.Inout.Typed.Valued Tests`.Unit {

    @Test
    func `valued accessor binds value generic in extension where-clause`() {
        var inline = Slice<Int>.Inline<5>(count: 3)

        #expect(inline.access.capacity == 5)
        #expect(inline.access.size == 3)
    }

    @Test
    func `valued accessor mutation writes through pointer`() {
        var inline = Slice<Int>.Inline<8>(count: 2)

        inline.access.resize(to: 7)
        #expect(inline.count == 7)
        #expect(inline.access.size == 7)
    }
}

extension `Property.Inout.Typed.Valued Tests`.Unit {

    /// Compile-time admission: the new `init(unsafeRawAddress:mutating:)` is
    /// only available when `Base: ~Copyable & ~Escapable`.
    @Test
    func `Property.Inout.Typed.Valued~Escapable type-level admission via init(unsafeRawAddress:mutating:)`() {
        // Closure exists for compile-time admission — never invoked.
        let _ = { (storage: UnsafeMutableRawPointer, owner: inout Int) in
            _ = unsafe Property<NEResource.Access, NEResource>.Inout.Typed<Int>.Valued<3>(
                unsafeRawAddress: storage,
                mutating: &owner
            )
        }
        #expect(true)
    }
}

extension `Property.Inout.Typed.Valued Tests`.`Edge Case` {

    @Test
    func `count is not constrained by the value generic n (phantom semantics)`() {
        // The value generic lifts an integer to the type level for
        // extension where-clause binding. It is NOT a runtime capacity
        // constraint — count can exceed or underflow n without trapping.
        var overCapacity = Slice<Int>.Inline<3>(count: 100)
        var underCapacity = Slice<Int>.Inline<3>(count: 0)

        #expect(overCapacity.access.capacity == 3)
        #expect(overCapacity.access.size == 100)

        #expect(underCapacity.access.capacity == 3)
        #expect(underCapacity.access.size == 0)
    }
}
