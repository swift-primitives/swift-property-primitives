import Testing
import Property_Primitives_Test_Support

@Suite
struct `Property.View Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.View Tests`.Unit {

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
        let view = Property<Box.Inspect, Box>.View(&box)
        let value = view.base.value.value

        #expect(value == 200)
    }

    @Test
    func `unsafe borrowing init: single read across module boundary`() {
        // Exercises Property.View(_ base: borrowing Base) — the @unsafe
        // init — from this test module, which is separate from
        // Property View Primitives. With the non-@inlinable workaround
        // in place, the release-mode @in_guaranteed ABI is preserved and
        // the stored pointer reads cleanly.
        let box = Box(value: 321)
        let view = unsafe Property<Box.Inspect, Box>.View(box)
        let first = view.base.value.value
        #expect(first == 321)
    }

    @Test
    func `unsafe borrowing init: multiple reads stable across module boundary`() {
        // Two successive reads against the same let-bound view exercise
        // the exact shape that the single-file minimal-repro demonstrates
        // crashes when @inlinable. With @inlinable removed, the
        // cross-module call boundary preserves the pointer.
        let box = Box(value: 654)
        let view = unsafe Property<Box.Inspect, Box>.View(box)
        let first = view.base.value.value
        let second = view.base.value.value
        #expect(first == 654)
        #expect(second == 654)
    }
}

extension `Property.View Tests`.Integration {

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
