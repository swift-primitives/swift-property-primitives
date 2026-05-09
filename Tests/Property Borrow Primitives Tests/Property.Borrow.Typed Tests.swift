import Property_Primitives_Test_Support
import Testing

@Suite
struct `Property.Borrow.Typed Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
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
