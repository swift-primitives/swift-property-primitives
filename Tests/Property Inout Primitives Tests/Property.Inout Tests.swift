import Property_Primitives_Test_Support
import Testing

@Suite
struct `Property.Inout Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.Inout Tests`.Unit {

    @Test
    func `pointer to stored property`() {
        let box = Box(value: 77)

        let result = unsafe Property<Box.Inspect, Box>.pointer(
            to: box.value
        ) { pointer in
            unsafe pointer.pointee * 2
        }

        #expect(result == 154)
    }

    @Test
    func `pointer mutating variant`() {
        var scalar = 50

        unsafe Property<Box.Inspect, Box>.pointer(
            to: &scalar,
            mutating: { pointer in
                unsafe pointer.pointee += 25
            }
        )

        #expect(scalar == 75)
    }

    @Test
    func `init from inout base enables value reads`() {
        var box = Box(value: 200)
        let accessor = Property<Box.Inspect, Box>.Inout(&box)
        let value = accessor.base.value.value

        #expect(value == 200)
    }

    @Test
    func `unsafe borrowing init: single read across module boundary`() {

        let box = Box(value: 321)
        let accessor = unsafe Property<Box.Inspect, Box>.Inout(box)
        let first = accessor.base.value.value
        #expect(first == 321)
    }

    @Test
    func `unsafe borrowing init: multiple reads stable across module boundary`() {

        let box = Box(value: 654)
        let accessor = unsafe Property<Box.Inspect, Box>.Inout(box)
        let first = accessor.base.value.value
        let second = accessor.base.value.value
        #expect(first == 654)
        #expect(second == 654)
    }
}

extension `Property.Inout Tests`.Integration {

    @Test
    func `pointer to tuple element`() {
        let box = Box(value: 10)

        let sum = unsafe Property<Box.Inspect, Box>.pointer(
            to: box.storage
        ) { pointer in
            let tuple = unsafe pointer.pointee
            return tuple.0 + tuple.1 + tuple.2 + tuple.3
        }

        #expect(sum == 10)
    }
}
