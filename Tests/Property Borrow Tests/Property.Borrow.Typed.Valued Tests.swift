import Property_Test_Support
import Testing

@Suite
struct `Property.Borrow.Typed.Valued Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.Borrow.Typed.Valued Tests`.Unit {

    @Test
    func `valued borrow accessor binds value generic in extension where-clause`() {
        var inline = Slice<Int>.Inline<7>(count: 4)

        #expect(inline.inspect.capacity == 7)
        #expect(inline.inspect.size == 4)
    }

    @Test
    func `borrowing init from let-bound valued base`() {
        let inline = Slice<Int>.Inline<5>(count: 3)

        let accessor = Property<
            Slice<Int>.Inline<5>.Inspect,
            Slice<Int>.Inline<5>
        >.Borrow.Typed<Int>.Valued<5>(inline)

        let count = accessor.base.value.count

        #expect(count == 3)
    }
}

extension `Property.Borrow.Typed.Valued Tests`.`Edge Case` {

    @Test
    func `valued borrow accessor does not mutate`() {
        var inline = Slice<Int>.Inline<3>(count: 2)

        let firstRead = inline.inspect.size
        let secondRead = inline.inspect.size

        #expect(firstRead == 2)
        #expect(secondRead == 2)
        #expect(inline.count == 2)
    }
}
