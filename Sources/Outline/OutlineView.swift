import SwiftUI

extension NSUserInterfaceItemIdentifier {
	static let outlineView = NSUserInterfaceItemIdentifier("com.chimehq.OutlineView")
	static let outlineContentColumn = NSUserInterfaceItemIdentifier("com.chimehq.OutlineView.Column.Content")
	static let outlineLoadingView = NSUserInterfaceItemIdentifier("com.chimehq.OutlineView.Loading")
	static let outlineContentView = NSUserInterfaceItemIdentifier("com.chimehq.OutlineView.Content")
}

public struct OutlineView<Value, Content: View, ID: Hashable>: NSViewRepresentable {
	public typealias ContentProvider = @MainActor (Value) -> Content
	public typealias ViewConfiguration = @MainActor (NSOutlineView) -> Void

	private let content: ContentProvider
	private let data: OutlineData<Value, ID>
	private let configuration: ViewConfiguration
	public var expansion: Binding<Set<ID>>
	public var selection: Binding<Set<ID>>

	public init(
		data: OutlineData<Value, ID>,
		expansion: Binding<Set<ID>>,
		selection: Binding<Set<ID>>,
		configuration: @escaping ViewConfiguration = { _ in },
		@ViewBuilder content: @escaping ContentProvider
	) {
		self.data = data
		self.expansion = expansion
		self.selection = selection
		self.content = content
		self.configuration = configuration
	}

	public func makeNSView(context: Context) -> NSOutlineView {
		let view = NSOutlineView()

		view.delegate = context.coordinator
		view.dataSource = context.coordinator

		let contentColumn = NSTableColumn(identifier: .outlineContentColumn)
		contentColumn.isEditable = false

		view.addTableColumn(contentColumn)

		view.headerView = nil
		view.allowsTypeSelect = true
		view.allowsMultipleSelection = true
		view.allowsColumnSelection = false
		view.allowsColumnReordering = false
		view.usesAutomaticRowHeights = true
		view.columnAutoresizingStyle = .reverseSequentialColumnAutoresizingStyle

		context.coordinator.outlineView = view

		configuration(view)

		return view
	}
	
	public func updateNSView(_ view: NSOutlineView, context: Context) {
		context.coordinator.data = data
//		context.coordinator.expandedItems = expansion.wrappedValue
	}

	public func makeCoordinator() -> OutlineViewCoordinator<Value, Content, ID> {
		OutlineViewCoordinator(
			data: data,
			expansion: expansion,
			selection: selection,
			content: content
		)
	}
}
