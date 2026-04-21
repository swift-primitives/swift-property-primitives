# ``Property_Primitives``

@Metadata {
    @DisplayName("Property Primitives")
    @TitleHeading("Swift Primitives")
    @PageColor(purple)
    @CallToAction(
        url: "doc:GettingStarted",
        purpose: link,
        label: "Start the Tutorial"
    )
}

Fluent accessor property type primitives — `stack.push.back(x)`,
`deque.peek.front`, `buffer.insert.front(element)` — without writing a
bespoke proxy struct per verb.

## Overview

``Property`` gives your container type a fluent accessor namespace through a
phantom-tag-discriminated wrapper. One container can expose many namespaces
(`push`, `pop`, `peek`, `insert`, `forEach`); each is a `Property` specialised
on a phantom `Tag` enum, each with its own extension surface.

Five variants extend `Property` along two axes — ownership mode (`Copyable`
vs `~Copyable`) and extension shape (method-case, property-case, read-only,
consuming, value-generic). A single consumer import — `Property_Primitives`
— pulls the full family; narrow variant imports are available for consumers
minimising their compile-time surface.

@Row {
    @Column {
        ### Start hands-on

        A seven-minute tutorial: build a `Stack<Element>` with
        `push.back(x)` and `peek.back` accessors.

        <doc:GettingStarted>
    }
    @Column {
        ### Choose a variant

        Decide which of the seven variants fits your container — Copyable
        vs `~Copyable`, method-case vs property-case, read-only vs mutating.

        <doc:Choosing-A-Property-Variant>
    }
    @Column {
        ### Understand the concept

        What phantom tags discriminate, and why ``Property`` and `Tagged`
        are separate primitives.

        <doc:Phantom-Tag-Semantics>
    }
}

## Topics

### Tutorials

- <doc:GettingStarted>

### Patterns

- <doc:Choosing-A-Property-Variant>
- <doc:CoW-Safe-Mutation-Recipe>
- <doc:~Copyable-Container-Patterns>
- <doc:Value-Generic-Verbosity-And-The-Tag-Enum-View-Pattern>

### Concepts

- <doc:Phantom-Tag-Semantics>

### Core Types

- ``Property``
- ``Property/Typed``
- ``Property/Consuming``
- ``Property/Consuming/State``

### `~Copyable` View Types

- ``Property/View-swift.struct``
- ``Property/View-swift.struct/Typed``
- ``Property/View-swift.struct/Typed/Valued``
- ``Property/View-swift.struct/Typed/Valued/Valued``

### Read-Only View Types

- ``Property/View-swift.struct/Read``
- ``Property/View-swift.struct/Read/Typed``
- ``Property/View-swift.struct/Read/Typed/Valued``
