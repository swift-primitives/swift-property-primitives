import Testing
import Property_Primitives_Test_Support

@Suite
struct `Property.View.Typed Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.View.Typed Tests`.Unit {

    @Test
    func `view typed basic usage`() {
        var slice = Slice<Int>(count: 5)
        #expect(slice.access.size == 5)
    }

    @Test
    func `view typed mutation writes through pointer`() {
        var slice = Slice<Int>(count: 5)

        slice.access.resize(to: 12)
        #expect(slice.count == 12)
        #expect(slice.access.size == 12)
    }
}

extension `Property.View.Typed Tests`.`Edge Case` {

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
