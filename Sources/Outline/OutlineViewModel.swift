import Foundation
import SwiftUI

@MainActor
final class OutlineViewModel<Value, ID: Hashable> {
	typealias LoadingTask = Task<Void, Error>
	typealias Configuration = OutlineConfiguration<Value>
	typealias ItemUpdatedHandler = (Item?) -> Void

	/// An item to be stored in the `NSOutlineView` tree structure.
	///
	/// The `Hashable` conformance is defined such that they match `NSOutlineView`'s concept of item equality and also remain stable as children are loaded.
	enum Item: Hashable, Identifiable {
		case node(Node)
		case loading(ID)

		var id: ID {
			switch self {
			case let .loading(valueId):
				return valueId
			case let .node(node):
				return node.id
			}
		}

		static func == (lhs: Item, rhs: Item) -> Bool {
			switch (lhs, rhs) {
			case (.loading, .loading), (.node, .node):
				return lhs.id == rhs.id
			default:
				return false
			}
		}

		func hash(into hasher: inout Hasher) {
			switch self {
			case .loading:
				hasher.combine(true)
			case .node:
				hasher.combine(false)
			}

			hasher.combine(id)
		}
	}

	final class Node {
		enum Children {
			case unknown
			case loading(LoadingTask)
			case loaded([Node])
		}

		let value: Value
		let id: ID
		var children = Children.unknown

		init(value: Value, id: ID) {
			self.value = value
			self.id = id
		}
	}

	private(set) var rootNode: Node {
		didSet { itemUpdatedHandler(nil) }
	}
	var data: OutlineData<Value, ID> {
		didSet {
			self.rootNode = Node(value: data.root, id: data.root[keyPath: data.id])
		}
	}
	var itemUpdatedHandler: ItemUpdatedHandler

	init(
		data: OutlineData<Value, ID>,
		itemUpdatedHandler: @escaping ItemUpdatedHandler
	) {
		self.data = data
		self.rootNode = Node(value: data.root, id: data.root[keyPath: data.id])
		self.itemUpdatedHandler = itemUpdatedHandler
	}

	var root: Value {
		rootNode.value
	}

	func id(for node: Node) -> ID {
		node.id
	}

	var rootItem: Item {
		.node(rootNode)
	}

	var rootId: ID {
		rootNode.id
	}

	func childCount(for item: Item) -> Int {
		guard case let .node(node) = item else {
			return 0
		}

		guard node.value[keyPath: data.hasSubvalues] else {
			return 0
		}

		switch childNodes(for: node) {
		case .unknown, .loading:
			return 1
		case let .loaded(children):
			return children.count
		}
	}

	func child(of item: Item, at index: Int) -> Item {
		guard case let .node(node) = item else {
			preconditionFailure("Loading items should not have children")
		}

		switch node.children {
		case .unknown, .loading:
			precondition(index == 0, "Can only ever have one child")
			return .loading(node.id)
		case let .loaded(subNodes):
			return .node(subNodes[index])
		}
	}

	func isItemExpandable(_ item: Item) -> Bool {
		guard case let .node(node) = item else {
			return false
		}

		switch node.children {
		case .unknown, .loaded:
			return node.value[keyPath: data.hasSubvalues]
		case .loading:
			return true
		}
	}

//	func item(for targetId: ID) -> Item? {
//		if rootId == targetId {
//			return rootItem
//		}
//
//		traverse(rootNode) { node in
//			let id = id(for: node)
//
//			if id == targetId {
//				return item(for: id)
//			}
//		}
//		for child in rootNode.children
//		rootNode.children
//	}
//
//	private func traverse(_ node: Node, block: (Node) -> Void) {
//		block(node)
//
//		if case let .loaded(nodes) = node.children {
//			for child in nodes {
//				traverse(child, block: block)
//			}
//		}
//	}
}

extension OutlineViewModel {
	private func childLoadingTask(for node: Node) -> Task<Void, Error> {
		Task { [data, itemUpdatedHandler] in
			let values = try await data.subValues(node.value)
			let children = values.map { Node(value: $0, id: $0[keyPath: data.id]) }

			node.children = .loaded(children)

			guard Task.isCancelled == false else { return }

			if node.id == rootId {
				itemUpdatedHandler(nil)
			} else {
				itemUpdatedHandler(Item.node(node))
			}
		}
	}

	private func childNodes(for node: Node) -> Node.Children {
		if case .unknown = node.children {
			let task = childLoadingTask(for: node)

			node.children = .loading(task)
		}

		return node.children
	}
}

