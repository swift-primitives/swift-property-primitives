public import Property_Primitives

public struct Stack<Element: Copyable>: Copyable {
    internal var _storage: [Element]

    public init() {
        self._storage = []
    }
}
