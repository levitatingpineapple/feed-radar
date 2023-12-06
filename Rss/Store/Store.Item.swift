import Foundation
import os.log
import GRDB

extension Store {
	var touchedItems: Array<Item> {
		(try? queue.write {
			try? Item
				.filter(
					Item.Column.isRead.column == true ||
					Item.Column.isStarred.column == true
				)
				.fetchAll($0)
		}) ?? Array<Item>()
	}
	
	func item(source: URL, itemId: String) -> Item? {
		try? queue.write {
			try item(source: source, itemId: itemId, $0)
		}
	}
	
	func item(source: URL, itemId: String, _ database: Database) throws -> Item? {
		try Item
			.filter(Column(Item.Column.source.rawValue) == source)
			.filter(Column(Item.Column.itemId.rawValue) == itemId)
			.fetchOne(database)
	}
 
	func update(item: Item) {
		try? queue.write { try item.update($0) }
		reselect(item: item)
	}
	
	func toggleRead(for item: Item) {
		try? queue.write {
			var newItem = item
			newItem.isRead.toggle()
			try newItem.update($0, columns: [Item.Column.isRead.rawValue])
		}
		Task { await sync.queueUpdated(item) }
	}
	
	func toggleStarred(for item: Item) {
		try? queue.write {
			var newItem = item
			newItem.isStarred.toggle()
			try newItem.update($0, columns: [Item.Column.isStarred.rawValue])
		}
		Task { await sync.queueUpdated(item) }
	}

	
	/// Fixes visual bug, where list item looses selection
	/// This bug does not affect navigation
	func reselect(item: Item?) {
		DispatchQueue.main.async {
			if self.item?.source == item?.source,
			   self.item?.itemId == item?.itemId {
				self.item = item
			}
		}
	}
}
