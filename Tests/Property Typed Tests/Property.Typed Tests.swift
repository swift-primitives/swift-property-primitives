import Property_Test_Support
import Property_Typed
import Testing

private typealias _TypedIsCopyable = Require.Copyable<Property::Property<Phantom, Int>.Typed<Int>>
private typealias _TypedIsSendable = Require.Sendable<Property::Property<Phantom, Int>.Typed<Int>>

@Suite
struct `Property.Typed Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property.Typed Tests`.Unit {

    @Test
    func `typed property basic usage`() {
        var typed = Property::Property<Phantom, Int>.Typed<Int>(42)
        #expect(typed.base == 42)

        typed.base = 100
        #expect(typed.base == 100)
    }
}
