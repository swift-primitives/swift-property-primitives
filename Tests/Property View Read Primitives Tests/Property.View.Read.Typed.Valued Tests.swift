import Testing
import Property_Primitives_Test_Support

@Suite
struct `Property.View.Read.Typed.Valued Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.View.Read.Typed.Valued Tests`.Unit {

    @Test
    func `valued read view binds value generic in extension where-clause`() {
        var inline = Slice<Int>.Inline<7>(count: 4)

        #expect(inline.inspect.capacity == 7)
        #expect(inline.inspect.size == 4)
    }

    @Test
    func `borrowing init from let-bound valued base`() {
        let inline = Slice<Int>.Inline<5>(count: 3)

        let view = Property<
            Slice<Int>.Inline<5>.Inspect,
            Slice<Int>.Inline<5>
        >.View.Read.Typed<Int>.Valued<5>(inline)

        let count = view.base.value.count

        #expect(count == 3)
    }
}

extension `Property.View.Read.Typed.Valued Tests`.`Edge Case` {

    @Test
    func `valued read view does not mutate`() {
        var inline = Slice<Int>.Inline<3>(count: 2)

        let firstRead = inline.inspect.size
        let secondRead = inline.inspect.size

        #expect(firstRead == 2)
        #expect(secondRead == 2)
        #expect(inline.count == 2)
    }
}
