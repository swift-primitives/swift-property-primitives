import Property_Inout
import Property_Test_Support
import Testing

@Suite
struct `Property.Inout.Typed.Valued.Valued Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.Inout.Typed.Valued.Valued Tests`.Unit {

    @Test
    func `double valued accessor binds both value generics`() {
        var inner = Slice<Int>.Inline<4>.Inner<9>(count: 3)

        #expect(inner.access.outer == 4)
        #expect(inner.access.inner == 9)
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

        #expect(inner.access.outer == 1)
        #expect(inner.access.inner == 1)
        #expect(inner.access.size == 0)

        inner.access.resize(to: 1)
        #expect(inner.access.size == 1)
    }
}
