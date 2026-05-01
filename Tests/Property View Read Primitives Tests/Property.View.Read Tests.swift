import Testing
import Property_Primitives_Test_Support

@Suite
struct `Property.View.Read Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.View.Read Tests`.Unit {

    @Test
    func `view read basic usage`() {
        var box = Box(value: 42)

        #expect(box.inspect.current == 42)
        #expect(box.inspect.first == 1)
    }

    @Test
    func `borrowing init with let binding`() {
        let box = Box(value: 42)

        #expect(box.borrow.current == 42)
        #expect(box.borrow.first == 1)
    }
}

extension `Property.View.Read Tests`.`Edge Case` {

    @Test
    func `view read does not mutate`() {
        var box = Box(value: 100)

        let first = box.inspect.current
        let second = box.inspect.current

        #expect(first == 100)
        #expect(second == 100)
    }

    @Test
    func `borrowing init supports multiple reads`() {
        let box = Box(value: 100)

        let first = box.borrow.current
        let second = box.borrow.current

        #expect(first == 100)
        #expect(second == 100)
    }
}
