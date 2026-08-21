import Property_Primitives_Test_Support
import Testing

@Suite
struct `Property.Inout.Typed Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
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

extension `Property.Inout.Typed Tests`.Integration {

    @Test
    func `condition-driven drain through inout view terminates`() {
        var slice = Slice<Int>(count: 3)
        #expect(slice.drainAll() == 3)
        #expect(slice.count == 0)
    }
}
