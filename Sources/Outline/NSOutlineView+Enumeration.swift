import AppKit

extension NSOutlineView {
	/// Enumerate all visible items in the view, including the root.
	///
	/// Mutating the expansion state of an item returned by the block during the enumeration is safe and supported. But, changing the expansion state in any other way is not.
	func enumerateItems(block: (Any?) -> Void) {
		recursivelyEnumerate(nil, block: block)
	}

	private func recursivelyEnumerate(_ item: Any?, block: (Any?) -> Void) {
		block(item)

		if isItemExpanded(item) == false {
			return
		}

		let count = numberOfChildren(ofItem: item)

		for i in 0..<count {
			guard let child = child(i, ofItem: item) else {
				continue
			}

			recursivelyEnumerate(child, block: block)
		}
	}

	func enumerateExpandedItems(block: (Any?) -> Void) {
		enumerateItems { (item) in
			if isItemExpanded(item) {
				block(item)
			}
		}
	}

	func rows(matching predicate: (Any?) -> Bool) -> IndexSet {
		var set = IndexSet()

		enumerateItems { item in
			if predicate(item) == false {
				return
			}

			let row = row(forItem: item)

			set.insert(row)
		}

		return set
	}
}

extension NSOutlineView {
	var expandedItems: [Any?] {
		var list: [Any?] = []

		enumerateExpandedItems { (item) in
			list.append(item)
		}

		return list
	}
}
