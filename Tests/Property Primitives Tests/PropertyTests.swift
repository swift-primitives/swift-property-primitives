import Testing
@testable import Property_Primitives

// MARK: - Test Types

/// A simple CoW container for testing the owned Property pattern.
struct Container<Element> {
    private var storage: [Element]

    init(_ elements: Element...) {
        storage = elements
    }

    var count: Int { storage.count }
    var isEmpty: Bool { storage.isEmpty }

    mutating func append(_ element: Element) {
        storage.append(element)
    }

    mutating func removeLast() -> Element {
        storage.removeLast()
    }

    func peek() -> Element? {
        storage.last
    }
}

// MARK: - Tag Types

extension Container {
    /// Tag type for push operations.
    enum Push {}

    /// Tag type for pop operations.
    enum Pop {}
}

// MARK: - Property Accessors

extension Container {
    /// Provides namespaced push operations.
    var push: Property<Container<Element>, Push> {
        _read { yield Property(self) }
        _modify {
            var property: Property<Container<Element>, Push> = Property(self)
            self = Container()
            defer { self = property.base }
            yield &property
        }
    }

    /// Provides namespaced pop operations.
    var pop: Property<Container<Element>, Pop> {
        _read { yield Property(self) }
        _modify {
            var property: Property<Container<Element>, Pop> = Property(self)
            self = Container()
            defer { self = property.base }
            yield &property
        }
    }
}

// MARK: - Property Extensions with Phantom Tags

extension Property<Container<Int>, Container<Int>.Push> {
    /// Appends an element to the container.
    mutating func back(_ element: Int) {
        base.append(element)
    }
}

extension Property<Container<Int>, Container<Int>.Pop> {
    /// Removes and returns the last element.
    mutating func back() -> Int {
        base.removeLast()
    }
}

// MARK: - Tests

@Suite
struct PropertyTests {
    @Test
    func ownedPropertyBasicUsage() {
        struct Tag {}

        var property = Property<Int, Tag>(42)
        #expect(property.base == 42)

        property.base = 100
        #expect(property.base == 100)
    }

    @Test
    func phantomTagExtensionIsolation() {
        // Verify that Push and Pop extensions don't interfere with each other
        var container = Container(1, 2, 3)

        // Push operations via phantom-tagged extension
        container.push.back(4)
        #expect(container.count == 4)

        // Pop operations via different phantom-tagged extension
        let popped = container.pop.back()
        #expect(popped == 4)
        #expect(container.count == 3)
    }

    @Test
    func modifyDeferPatternPreservesState() {
        var container = Container(10, 20, 30)

        // The _modify + defer pattern should preserve container state
        container.push.back(40)
        container.push.back(50)

        #expect(container.count == 5)
        #expect(container.peek() == 50)
    }

    @Test
    func multipleOperationsInSequence() {
        var container = Container<Int>()

        // Multiple pushes
        container.push.back(1)
        container.push.back(2)
        container.push.back(3)
        #expect(container.count == 3)

        // Multiple pops
        #expect(container.pop.back() == 3)
        #expect(container.pop.back() == 2)
        #expect(container.count == 1)

        // Interleaved
        container.push.back(4)
        #expect(container.pop.back() == 4)
        #expect(container.pop.back() == 1)
        #expect(container.isEmpty)
    }
}

// MARK: - Nested Tag Tests

extension Container {
    /// Namespace for merge operations.
    enum Merge {
        /// Tag for keep-existing behavior.
        enum Keep {}
        /// Tag for replace behavior.
        enum Replace {}
    }
}

extension Container {
    /// Provides namespaced merge.keep operations.
    var mergeKeep: Property<Container<Element>, Merge.Keep> {
        _read { yield Property(self) }
        _modify {
            var property: Property<Container<Element>, Merge.Keep> = Property(self)
            self = Container()
            defer { self = property.base }
            yield &property
        }
    }
}

extension Property<Container<Int>, Container<Int>.Merge.Keep> {
    /// Merge operation that keeps existing values.
    mutating func merge(from other: Container<Int>) {
        // Append all elements for this test
        for _ in 0..<other.count {
            // Simplified placeholder
        }
    }
}

@Suite
struct NestedTagTests {
    @Test
    func nestedPhantomTagsCompile() {
        // This test verifies that nested phantom tags work
        // (e.g., Merge.Keep as a two-level nested tag)
        var container = Container(1, 2, 3)

        // Access the nested-tagged property - verifies compilation
        container.mergeKeep.merge(from: Container(4, 5))

        #expect(container.count == 3)
    }
}
