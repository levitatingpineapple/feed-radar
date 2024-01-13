import Foundation
import os.log
import GRDB

extension Store {
	/// Items that user has interacted with and need to be synced.
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
	
	func item(id: Item.ID) -> Item? {
		try? queue.write {
			try Item.filter(id: id).fetchOne($0)
		}
	}
 
	func update(item: Item) {
		try? queue.write { try item.update($0) }
	}
	
	func update(items: Array<Item>) {
		try? queue.write {
			for item in items {
				try item.update($0)
			}
		}
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
	
	func markAsRead(itemId: Item.ID) {
		if let item = self.item(id: itemId), item.isRead == false {
			self.toggleRead(for: item)
		}
	}
	
	func attachments(itemId: Item.ID) -> Array<Attachment>? {
		try? queue.write {
			try Attachment
				.filter(Attachment.CodingKeys.itemId.column == itemId)
				.fetchAll($0)
		}
	}
}
