import SwiftUI

@MainActor
public final class OutlineViewCoordinator<Value, Content: View, ID: Hashable>: NSObject, NSOutlineViewDelegate, NSOutlineViewDataSource {
	typealias View = OutlineView<Value, Content, ID>
	typealias ContentProvider = View.ContentProvider
	typealias Model = OutlineViewModel<Value, ID>
	typealias Item = Model.Item

	private let model: Model
	var expansion: Binding<Set<ID>> {
		didSet { expansionStateUpdated() }
	}
	private let selection: Binding<Set<ID>>
	private let content: ContentProvider
	var outlineView: NSOutlineView! {
		didSet {
			outlineView.delegate = self
			outlineView.dataSource = self
		}
	}

	init(
		data: OutlineData<Value, ID>,
		expansion: Binding<Set<ID>>,
		selection: Binding<Set<ID>>,
		content: @escaping ContentProvider
	) {
		self.content = content
		self.expansion = expansion
		self.selection = selection

		self.model = OutlineViewModel(
			data: data,
			itemUpdatedHandler: { _ in }
		)

		super.init()

		model.itemUpdatedHandler = { [weak self] in self?.reloadItem($0) }
	}

	var data: OutlineData<Value, ID> {
		get { model.data }
		set {
			let newId = newValue.root[keyPath: newValue.id]

			if model.rootId == newId {
				return
			}

			model.data = newValue

			outlineView.autosaveName = Self.autosaveName(with: model.rootId)
			outlineView.autosaveExpandedItems = outlineView.autosaveName != nil
		}
	}

	private func reloadItem(_ item: Item?) {
		outlineView.reloadItem(item, reloadChildren: true)
	}

	// MARK: NSOutlineViewDataSource
	public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
		let item = (item ?? model.rootItem) as! Item

		return model.childCount(for: item)
	}

	public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
		let item = (item ?? model.rootItem) as! Item

		return model.child(of: item, at: index)
	}

	public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
		let item = item as! Item

		return model.isItemExpandable(item)
	}

//	public func outlineView(_ outlineView: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
//		// have to fill this back in
//		nil
//	}
//
//	public func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
////		(item as? Model.Node)?.value
//		nil
//	}

	// MARK: NSOutlineViewDelegate
	public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
		let item = item as! Item

		guard tableColumn != nil else { return nil }

		switch item {
		case .loading:
			let view = outlineView.makeReusableView(for: .outlineLoadingView) {
				NSHostingView(rootView: Text("loading"))
			}

			return view
		case let .node(node):
			let content = content(node.value)
			let view = outlineView.makeReusableView(for: .outlineContentView) {
				NSHostingView(rootView: content)
			}

			view.rootView = content

			return view
		}
	}

	public func outlineViewItemDidCollapse(_ notification: Notification) {
		let item = notification.userInfo?["NSObject"] as! Item

		guard case let .node(node) = item else {
			preconditionFailure("Can only change expansion state of nodes")
		}

		let id = model.id(for: node)

		expansion.wrappedValue.remove(id)
	}

	public func outlineViewItemDidExpand(_ notification: Notification) {
		let item = notification.userInfo?["NSObject"] as! Item

		guard case let .node(node) = item else {
			preconditionFailure("Can only change expansion state of nodes")
		}

		let id = model.id(for: node)

		expansion.wrappedValue.insert(id)
	}

	public func outlineViewSelectionDidChange(_ notification: Notification) {
		let ids = outlineView.selectedRowIndexes
			.map { outlineView.item(atRow: $0) }
			.map {
				guard case let .node(node) = $0 as! Item else {
					preconditionFailure("Can only change selection state of nodes")
				}

				return node
			}
			.map { model.id(for: $0) }

		selection.wrappedValue = Set(ids)
	}
}

extension OutlineViewCoordinator {
	private static func autosaveName(with valueId: ID) -> String? {
		guard UserDefaults.standard.bool(forKey: "ApplePersistenceIgnoreState") == false else {
			return nil
		}

		let id = NSUserInterfaceItemIdentifier.outlineView

		return "\(id)-\(valueId)"
	}

	private var expandedItems: Set<ID> {
		get {
			let ids = outlineView.expandedItems
				.compactMap {
					switch $0 as? Item {
					case let .node(node):
						return node
					default:
						return nil
					}
				}
				.map { model.id(for: $0) }

			return Set(ids)
		}
		set {
			let currentItems = expandedItems
			if currentItems == newValue {
				return
			}

		}
	}

	private func expansionStateUpdated() {
		expandedItems = expansion.wrappedValue
	}
}
