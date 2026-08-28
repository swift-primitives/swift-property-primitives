import Property_Carrier
import Testing

private enum Fixture {}

@Suite
struct `Property Carrier Tests` {
    @Test
    func `Property exposes its underlying value through Carrier`() {
        let property = Property::Property<Fixture, Int>(42)
        #expect(property.underlying == 42)
    }
}
