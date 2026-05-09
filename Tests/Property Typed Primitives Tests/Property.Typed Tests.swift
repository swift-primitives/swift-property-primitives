import Property_Primitives_Test_Support
import Testing

// MARK: - Compile-time conformance assertions

private typealias _TypedIsCopyable = RequireCopyable<Property<Phantom, Int>.Typed<Int>>
private typealias _TypedIsSendable = RequireSendable<Property<Phantom, Int>.Typed<Int>>

// MARK: - Type-level admission of ~Escapable Base
//
// If `Property.Typed` regresses to require `Base: Escapable`, this typealias
// fails to compile. NEResource is `~Copyable & ~Escapable` per the cohort's
// canonical fixture pattern.
private typealias _TypedAdmitsNEResource = Property<NEResource.Inspect, NEResource>.Typed<Int>

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
