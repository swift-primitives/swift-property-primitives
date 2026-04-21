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

        let result = unsafe Property<Box.Inspect, Box>.View.pointer(
            to: box.value
        ) { pointer in
            unsafe pointer.pointee * 2
        }

        #expect(result == 154)
    }

    @Test
    func `pointer mutating variant`() {
        var scalar = 50

        unsafe Property<Box.Inspect, Box>.View.pointer(
            to: &scalar,
            mutating: { pointer in
                unsafe pointer.pointee += 25
            }
        )

        #expect(scalar == 75)
    }

    @Test
    func `unsafe init from borrowing base enables pointer reads`() {
        // The flat form is deliberate. Wrapping the view construction in an
        // IIFE (`let v = unsafe { let view = ...; return ... }()`) trips the
        // Swift 6.3.1 SendNonSendable SILFunctionTransform — the compiler
        // aborts with signal 6. Minimum reproducer:
        //   swift-institute/Experiments/sendnonsendable-iife-borrowing-init-crash/
        let box = Box(value: 200)
        let view = unsafe Property<Box.Inspect, Box>.View(box)
        let pointeeValue = unsafe view.base.pointee.value

        #expect(pointeeValue == 200)
    }
}

extension `Property.View Tests`.Integration {

    @Test
    func `pointer to tuple element`() {
        let box = Box(value: 10)

        let sum = unsafe Property<Box.Inspect, Box>.View.pointer(
            to: box.storage
        ) { pointer in
            let tuple = unsafe pointer.pointee
            return tuple.0 + tuple.1 + tuple.2 + tuple.3
        }

        #expect(sum == 10)
    }
}
