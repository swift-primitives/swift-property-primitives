import Testing
import Property_Primitives_Test_Support

@Suite
struct `Property.View.Typed.Valued Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.View.Typed.Valued Tests`.Unit {

    @Test
    func `valued view binds value generic in extension where-clause`() {
        var inline = Slice<Int>.Inline<5>(count: 3)

        #expect(inline.access.capacity == 5)
        #expect(inline.access.size == 3)
    }

    @Test
    func `valued view mutation writes through pointer`() {
        var inline = Slice<Int>.Inline<8>(count: 2)

        inline.access.resize(to: 7)
        #expect(inline.count == 7)
        #expect(inline.access.size == 7)
    }
}

extension `Property.View.Typed.Valued Tests`.`Edge Case` {

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
