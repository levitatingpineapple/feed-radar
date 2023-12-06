import Foundation
import GRDB
import os.log
import FeedKit


extension Store {
	var feeds: Array<Feed> {
		(try? queue.write {
			try? Feed
				.order(Feed.Column.title.column)
				.reversed()
				.fetchAll($0)
		}) ?? Array<Feed>()
	}
	
	private func feed(source: URL, _ database: Database) throws -> Feed? {
		try Feed
			.filter(Column(Feed.Column.source.rawValue) == source)
			.fetchOne(database)
	}
	
	func add(feed: Feed, userInitiated: Bool = true) {
		if (
			try? queue.write {
				try Feed
					.filter(Column(Item.Column.source.rawValue) == feed.source)
					.isEmpty($0)
			}
		) ?? true {
			try? queue.write { try feed.insert($0) }
			Task { await fetch(feed: feed) }
			if userInitiated {
				Task { await self.sync.queueAdded(feed) }
			}
		}
	}
	
	func delete(feed: Feed, userInitiated: Bool = true) {
		try? queue.write { let _ = try feed.delete($0) }
		if userInitiated {
			Task { await self.sync.queueDeleted(feed) }
		}
	}
	
	func deleteAllFeeds() {
		try? queue.write {
			let _  = try Feed.deleteAll($0)
		}
		try? FileManager.default.removeItem(
			at: URL.documents.appendingPathComponent("attachments")
		)
	}
	
	func markAllAsRead(feed: Feed) {
		try? queue.write {
			var unread: QueryInterfaceRequest<Item> {
				Item
					.filter(Column(Item.Column.source.rawValue) == feed.source)
					.filter(Item.Column.isRead.column == false)
			}
			if let items = try? unread.fetchAll($0) {
				try unread.updateAll($0, [Item.Column.isRead.column.set(to: true)])
				Task {
					for item in items { await sync.queueUpdated(item) }
				}
			}
		}
	}
	
	func fetch(feed: Feed? = nil) async {
		await FeedFetcher.shared.fetch(
			sources: feed.flatMap { [$0.source] } ?? self.feeds.map { $0.source },
			workers: 3
		) { data, source in
			switch FeedParser(data: data).parse() {
			case let .success(feed):
				try? queue.write {
					let mapped = Mapped(feed: feed, at: source)
					
					// 1. Check if feed has changed. Insert and fetch it's icon
					if mapped.feed != (try? self.feed(source: mapped.feed.source, $0)) {
						try? mapped.feed.insert($0)
						Task {
							if let iconUrl = mapped.feed.icon,
							   let iconData = try? Data(contentsOf: iconUrl),
							   let icon = iconData.scaledPng {
								UserDefaults.standard.setValue(icon, forKey: .iconKey(source: mapped.feed.source))
							}
						}
					}
					
					// 2. Items: Merge fetched items with synced state (isRead, isStarred) and insert
					for var item in mapped.items {
						if let stored = try? self.item(source: item.source, itemId: item.itemId, $0) {
							item.isRead = stored.isRead
							item.isStarred = stored.isStarred
							item.sync = stored.sync
							item.extracted = stored.extracted
							if stored == item { continue } // Skip unchanged items
						}
						try? item.insert($0)
					}
					
					// 3. Insert attachements
					for attachment in mapped.attachments { try? attachment.insert($0) }
					
					// 4. Process orphaned sync records
					Task { await self.sync.processOrphanedRecords(for: mapped.feed) }
				}
			case let .failure(error):
				Logger.store.error("Parses Error \(error)")
			}
		}
	}
	
}
