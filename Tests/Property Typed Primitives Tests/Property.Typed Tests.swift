import Testing
import Property_Primitives_Test_Support

// MARK: - Compile-time conformance assertions

private typealias _TypedIsCopyable = RequireCopyable<Property<Phantom, Int>.Typed<Int>>
private typealias _TypedIsSendable = RequireSendable<Property<Phantom, Int>.Typed<Int>>

@Suite
struct `Property.Typed Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.Typed Tests`.Unit {

    @Test
    func `typed property basic usage`() {
        var typed = Property<Phantom, Int>.Typed<Int>(42)
        #expect(typed.base == 42)

        typed.base = 100
        #expect(typed.base == 100)
    }
}
