import Testing
import Property_Primitives_Test_Support

// MARK: - Compile-time conformance assertions

private typealias _PropertyIsCopyable = RequireCopyable<Property<Phantom, Int>>
private typealias _PropertyIsSendable = RequireSendable<Property<Phantom, Int>>

@Suite
struct `Property Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

extension `Property Tests`.Unit {

    @Test
    func `owned property basic usage`() {
        var property = Property<Phantom, Int>(42)
        #expect(property.base == 42)

        property.base = 100
        #expect(property.base == 100)
    }

    @Test
    func `nested phantom tags compile`() {
        var container = Container(1, 2, 3)
        container.merge.from(Container(4, 5))
        #expect(container.count == 3)
    }
}

extension `Property Tests`.Integration {

    @Test
    func `phantom tag extensions isolated per tag`() {
        var container = Container(1, 2, 3)

        container.push.back(4)
        #expect(container.count == 4)

        let popped = container.pop.back()
        #expect(popped == 4)
        #expect(container.count == 3)
    }

    @Test
    func `modify defer pattern preserves state`() {
        var container = Container(10, 20, 30)

        container.push.back(40)
        container.push.back(50)

        #expect(container.count == 5)
        #expect(container.peek() == 50)
    }

    @Test
    func `multiple operations in sequence`() {
        var container = Container<Int>()

        container.push.back(1)
        container.push.back(2)
        container.push.back(3)
        #expect(container.count == 3)

        #expect(container.pop.back() == 3)
        #expect(container.pop.back() == 2)
        #expect(container.count == 1)

        container.push.back(4)
        #expect(container.pop.back() == 4)
        #expect(container.pop.back() == 1)
        #expect(container.isEmpty)
    }
}
