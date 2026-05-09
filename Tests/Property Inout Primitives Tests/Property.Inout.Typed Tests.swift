import Property_Primitives_Test_Support
import Testing

// MARK: - Type-level admission of ~Escapable Base
//
// If `Property.Inout.Typed` regresses to require `Base: Escapable`, the
// admission test below fails to compile.

@Suite
struct `Property.Inout.Typed Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.Inout.Typed Tests`.Unit {

    /// Compile-time admission: the new `init(unsafeRawAddress:mutating:)` is
    /// only available when `Base: ~Copyable & ~Escapable`.
    @Test
    func `Property.Inout.Typed~Escapable type-level admission via init(unsafeRawAddress:mutating:)`() {
        // Closure exists for compile-time admission — never invoked.
        let _ = { (storage: UnsafeMutableRawPointer, owner: inout Int) in
            _ = unsafe Property<NEResource.Access, NEResource>.Inout.Typed<Int>(
                unsafeRawAddress: storage,
                mutating: &owner
            )
        }
        #expect(true)
    }
}

extension `Property.Inout.Typed Tests`.Unit {

    @Test
    func `inout typed basic usage`() {
        var slice = Slice<Int>(count: 5)
        #expect(slice.access.size == 5)
    }

    @Test
    func `inout typed mutation writes through pointer`() {
        var slice = Slice<Int>(count: 5)

        slice.access.resize(to: 12)
        #expect(slice.count == 12)
        #expect(slice.access.size == 12)
    }
}

extension `Property.Inout.Typed Tests`.`Edge Case` {

    @Test
    func `sequential mutations each persist independently`() {
        var slice = Slice<Int>(count: 0)

        slice.access.resize(to: 5)
        let afterFirst = slice.access.size

        slice.access.resize(to: 12)
        let afterSecond = slice.access.size

        slice.access.resize(to: 3)
        let afterThird = slice.access.size

        #expect(afterFirst == 5)
        #expect(afterSecond == 12)
        #expect(afterThird == 3)
        #expect(slice.count == 3)
    }
}
