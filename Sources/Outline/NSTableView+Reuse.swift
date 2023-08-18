import AppKit

extension NSTableView {
	func makeReusableView<T: NSView>(for identifier: NSUserInterfaceItemIdentifier, owner: Any? = nil, generator: () -> T) -> T {
		let view = makeView(withIdentifier: identifier, owner: owner)

		if let reusedView = view as? T {
			return reusedView
		}

		return generator()
	}
}
