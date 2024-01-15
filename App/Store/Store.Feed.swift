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
	
	/// Adds feed and fetches it's items
	/// - Parameters:
	///   - feed: Feed to add
	///   - userInitiated: Only syncs is initiated by user to prevent feedback loops
	func add(feed: Feed, userInitiated: Bool = true) async {
		if await (
			try? queue.write {
				try Feed
					.filter(Column(Item.Column.source.rawValue) == feed.source)
					.isEmpty($0)
			}
		) ?? true {
			try? await queue.write { try feed.insert($0) }
			await fetch(feed: feed)
			if userInitiated { await self.sync?.added(feed) }
		}
	}
	
	/// Removes feed from database, deletes it's attachments and prefrences
	/// - Parameters:
	///   - feed: Feed to remove
	///   - userInitiated: Only syncs is initiated by user to prevent feedback loops
	func delete(feed: Feed, userInitiated: Bool = true) {
		try? queue.write { let _ = try feed.delete($0) }
		[
			String.iconKey(source: feed.source),
			String.displayKey(source: feed.source),
			String.conditionalHeadersKey(source: feed.source),
		].forEach { UserDefaults.standard.removeObject(forKey: $0) }
		if userInitiated {
			Task { await self.sync?.deleted(feed) }
		}
	}
	
	/// Called when user signs out of iCloud account
	func clearAllData() {
		try? queue.write {
			let _  = try Feed.deleteAll($0)
		}
		try? FileManager.default.removeItem(
			at: URL.documents.appendingPathComponent("attachments")
		)
		if let bundleID = Bundle.main.bundleIdentifier {
			UserDefaults.standard.removePersistentDomain(forName: bundleID)
		}
	}
	
	/// Marks all filtered unread items as read and ques them for sync
	func markAllAsRead(filter: Filter) {
		let request = filter.unread.items
		
		// Fetch items before updating
		let items = (
			try? queue.write {
				try request.fetchAll($0)
			}
		) ?? Array<Item>()
		try? queue.write {
			 let updatedCount = try request.updateAll(
				$0,
				[Item.Column.isRead.column.set(to: true)]
			 )
			Logger.store.info("Marked \(updatedCount) items as read")
		}
		Task {
			for item in items { await self.sync?.updated(item) }
		}
	}
	
	/// Fetches all feeds if last fetch was more than `elapsed` seconds ago.
	/// Used for triggering fetch after the app enters foreground
	func fetch(after elapsed: TimeInterval) {
		if Date.now.timeIntervalSince1970 - (lastFullFetch ?? .zero) > elapsed {
			Task { await fetch() }
		}
	}
	
	/// Fetches feed and updates the database. If no feed is provided - fetches all feeds
	func fetch(feed: Feed? = nil) async {
		if feed == nil { lastFullFetch = Date.now.timeIntervalSince1970 }
		await fetcher.fetch(
			sources: feed.flatMap { [$0.source] } ?? self.feeds.map { $0.source },
			workers: 8
		) { data, source in
			if data.isEmpty { return } // Response body is empty if server reponds with 304 (Not Modified)
			switch FeedParser(data: data).parse() {
			case let .success(feed):
				try? queue.write {
					let mapped = Mapped(parsed: feed, from: source)
					
					// 1. If feed has changed, insert and fetch it's icon
					if mapped.feed != (
						try? Feed
							.filter(Feed.Column.source.column == source)
							.fetchOne($0)
					) {
						try? mapped.feed.upsert($0)
						Task {
							if let iconUrl = mapped.feed.icon,
							   let iconData = try? Data(contentsOf: iconUrl),
							   let icon = iconData.scaledPng {
								UserDefaults.standard.setValue(
									icon,
									forKey: .iconKey(source: mapped.feed.source)
								)
							}
						}
					}
					
					// 2. Merge fetched items with synced state (isRead, isStarred) and insert
					for content in mapped.contents {
						var item = content.item
						var itemChanged = true
						if let stored = try? Item.filter(id: content.item.id).fetchOne($0) {
							item.isRead = stored.isRead
							item.isStarred = stored.isStarred
							item.sync = stored.sync
							item.extracted = stored.extracted
							itemChanged = item != stored
						}
						if itemChanged { try? item.insert($0) }
						let _ = try Attachment
							.filter(Attachment.CodingKeys.itemId.column == item.id)
							.deleteAll($0)
						for attachment in content
							.attachments { try? attachment.insert($0) }
					}
					
					// 4. Process orphaned sync records
					Task { await self.sync?.processOrphanedRecords(for: mapped.feed) }
					
				}
			case let .failure(error):
				Logger.store.error("Parses Error \(error)")
			}
		}
	}
}
