import Foundation
import Combine
import FeedKit
import GRDB
import os.log
import NotificationCenter

class Store: ObservableObject {
	let queue: DatabaseQueue
	static let shared = try! Store() // TODO: Inject as environment object
	private let sync = Sync()
	private var bag = Set<AnyCancellable>()
	
	@Published var filter: Item.Filter?
	@Published var item: Item?
	
	init() throws {
		var configuration = Configuration()
//		configuration.publicStatementArguments = true
//		configuration.prepareDatabase {
//			$0.trace { Logger.store.trace("\($0.description)") }
//		}
		queue = try DatabaseQueue(
			path: URL.documents.appendingPathComponent("rss.db").path,
			configuration: configuration
		)
		try queue.write {
			try Feed.createTable(database: $0)
			try Item.createTable(database: $0)
			try Attachment.createTable(database: $0)
		}

		filter = UserDefaults.standard
			.data(forKey: .filterKey)
			.flatMap { Item.Filter(rawValue: $0) }
		$filter
			.removeDuplicates()
			.sink { UserDefaults.standard.setValue($0?.rawValue, forKey: .filterKey) }
			.store(in: &bag)
		$item
			.removeDuplicates()
			.scan((Optional<Item>.none, Optional<Item>.none)) { ($0.1, $1) }
			.sink { (deselected, selected) in
				if let deselected, deselected.isRead == false {
					self.toggleRead(for: deselected)
					self.reselect(item: selected)
				}
			}
			.store(in: &bag)
		Item.RequestCount(filter: Item.Filter(isRead: false))
			.publisher(in: self)
			.replaceError(with: .zero)
			.sink { UNUserNotificationCenter.current().setBadgeCount($0) }
			.store(in: &bag)
	}
	
	// MARK: Feed
	
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
	
	// MARK: Item
	
	var touchedItems: Array<Item> {
		(try? queue.write {
			try? Item
				.filter(Item.Column.isRead.column == true || Item.Column.isStarred.column == true)
				.fetchAll($0)
		}) ?? Array<Item>()
	}
	
	func item(source: URL, itemId: String) -> Item? {
		try? queue.write {
			try item(source: source, itemId: itemId, $0)
		}
	}
	
	private func item(source: URL, itemId: String, _ database: Database) throws -> Item? {
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
	/// It does not affect navigation
	private func reselect(item: Item?) {
		DispatchQueue.main.async {
			if self.item?.source == item?.source,
			   self.item?.itemId == item?.itemId {
				self.item = item
			}
		}
	}
	
	// MARK: Attachment
	
	func removeAttachments(source: URL, itemId: String? = nil) {
		var predicate: some SQLSpecificExpressible {
			if let itemId {
				Attachment.Column.source.column == source &&
				Attachment.Column.itemId.column == itemId
			} else {
				Attachment.Column.source.column == source
			}
		}
		try? queue.write {
			if let attachments = try? Attachment.filter(predicate).fetchAll($0) {
				attachments.forEach {
					try? FileManager.default.removeItem(at: $0.localUrl.deletingLastPathComponent())
					Downloader.shared.tasks.removeValue(forKey: $0.url)
				}
			}
		}
	}
}
