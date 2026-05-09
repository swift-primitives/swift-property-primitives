import Property_Primitives_Test_Support
import Testing

// MARK: - Type-level admission of ~Escapable Base
//
// If `Property.Inout.Typed.Valued.Valued` regresses to require
// `Base: Escapable`, the admission test below fails to compile.

@Suite
struct `Property.Inout.Typed.Valued.Valued Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.Inout.Typed.Valued.Valued Tests`.Unit {

    /// Compile-time admission: the new `init(unsafeRawAddress:mutating:)` is
    /// only available when `Base: ~Copyable & ~Escapable`.
    @Test
    func `Property.Inout.Typed.Valued.Valued~Escapable type-level admission via init(unsafeRawAddress:mutating:)`() {
        // Closure exists for compile-time admission — never invoked.
        let _ = { (storage: UnsafeMutableRawPointer, owner: inout Int) in
            _ = unsafe Property<NEResource.Access, NEResource>.Inout.Typed<Int>.Valued<3>.Valued<5>(
                unsafeRawAddress: storage,
                mutating: &owner
            )
        }
        #expect(true)
    }
}

extension `Property.Inout.Typed.Valued.Valued Tests`.Unit {

    @Test
    func `double valued accessor binds both value generics`() {
        var inner = Slice<Int>.Inline<4>.Inner<9>(count: 3)

        #expect(inner.access.outerCapacity == 4)
        #expect(inner.access.innerCapacity == 9)
        #expect(inner.access.size == 3)
    }

    @Test
    func `double valued accessor mutation writes through pointer`() {
        var inner = Slice<Int>.Inline<2>.Inner<6>(count: 1)

        inner.access.resize(to: 5)
        #expect(inner.count == 5)
        #expect(inner.access.size == 5)
    }
}

extension `Property.Inout.Typed.Valued.Valued Tests`.`Edge Case` {

    @Test
    func `minimum value-generics n=1 m=1 are well-formed`() {
        var inner = Slice<Int>.Inline<1>.Inner<1>(count: 0)

        #expect(inner.access.outerCapacity == 1)
        #expect(inner.access.innerCapacity == 1)
        #expect(inner.access.size == 0)

        inner.access.resize(to: 1)
        #expect(inner.access.size == 1)
    }
}
