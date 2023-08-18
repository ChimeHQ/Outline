import Foundation

@MainActor
public struct OutlineConfiguration<Value> {
	public typealias ValueProvider = @MainActor (Value) async throws -> [Value]
	public typealias HasSubvaluesProvider = (Value) -> Bool

	public let subValues: ValueProvider
	public let hasSubvalues: HasSubvaluesProvider

	public init(
		subValues: @escaping ValueProvider,
		hasSubvalues: @escaping HasSubvaluesProvider
	) {
		self.subValues = subValues
		self.hasSubvalues = hasSubvalues
	}
}

@MainActor
public struct OutlineData<Value, ID: Hashable> {
	public typealias ValueProvider = @MainActor (Value) async throws -> [Value]

	public var root: Value
	public let subValues: ValueProvider
	public let id: KeyPath<Value, ID>
	public let hasSubvalues: KeyPath<Value, Bool>

	public init(
		root: Value,
		subValues: @escaping ValueProvider,
		id: KeyPath<Value, ID>,
		hasSubvalues: KeyPath<Value, Bool>
	) {
		self.root = root
		self.subValues = subValues
		self.id = id
		self.hasSubvalues = hasSubvalues
	}
}
