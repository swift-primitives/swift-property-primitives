public import Carrier_Primitives
public import Property_Primitive

extension Property: Carrier.`Protocol` where Base: ~Copyable {

    public typealias Underlying = Base

    public typealias Domain = Tag

    @inlinable
    public var underlying: Base {
        _read { yield base }
    }
}
