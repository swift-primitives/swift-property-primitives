import Testing
import Property_Primitives_Test_Support

@Suite
struct `Property.View.Read.Typed Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.View.Read.Typed Tests`.Unit {

    @Test
    func `view read typed basic usage`() {
        var slice = Slice<Int>(count: 5)

        #expect(slice.peek.size == 5)
    }

    @Test
    func `borrowing typed init with let binding`() {
        let slice = Slice<Int>(count: 7)

        #expect(slice.borrow.size == 7)
    }
}
