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
	
	var selectedItem: Item? {
		itemId.flatMap { item(id: $0) }
	}
	
	func item(id: Item.ID) -> Item? {
		try? queue.write {
			try Item.filter(id: id).fetchOne($0)
		}
	}
 
	func update(item: Item) {
		try? queue.write { try item.update($0) }
	}
	
	func toggleRead(for item: Item) {
		try? queue.write {
			var newItem = item
			newItem.isRead.toggle()
			try newItem.update($0, columns: [Item.Column.isRead.rawValue])
		}
		Task { await sync?.updated(item) }
	}
	
	func toggleStarred(for item: Item) {
		try? queue.write {
			var newItem = item
			newItem.isStarred.toggle()
			try newItem.update($0, columns: [Item.Column.isStarred.rawValue])
		}
		Task { await sync?.updated(item) }
	}
}
