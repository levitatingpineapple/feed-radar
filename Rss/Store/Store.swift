import Foundation
import Combine
import FeedKit
import GRDB
import os.log

class Store: ObservableObject {
	static let shared = try! Store()
	let queue: DatabaseQueue
	private let sync = Sync()
	private var bag = Set<AnyCancellable>()
	@Published var fetching = Set<URL>()
	@Published var filter: Item.Filter?
	@Published var item: Item?
	
	init() throws {
		var configuration = Configuration()
		configuration.publicStatementArguments = true
		configuration.prepareDatabase {
			$0.trace { Logger.store.log("\($0.description)") }
		}
		queue = try DatabaseQueue(
			path: URL.documents.appendingPathComponent("rss.db").path,
			configuration: configuration
		)
		try queue.write {
			try Feed.createTable(database: $0)
			try Item.createTable(database: $0)
			try Attachment.createTable(database: $0)
		}
		$item
			.removeDuplicates()
			.scan((Optional<Item>.none, Optional<Item>.none)) { ($0.1, $1) }
			.sink { (deselect, select) in
				if let deselect, deselect.isRead == false {
					self.toggleRead(for: deselect)
					DispatchQueue.main.async { self.item = select }
				}
			}
			.store(in: &bag)
	}
	
	func isNewFeed(source: URL) -> Bool {
		(try? queue.write { 
			try isNewFeed(source: source, $0)}
		) ?? true
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
	
	private func isNewFeed(source: URL, _ database: Database) throws -> Bool {
		try Feed
			.filter(Column(Item.Column.source.rawValue) == source)
			.isEmpty(database)
	}
 
	func update(item: Item) {
		try? queue.write {
			try item.insert($0)
		}
	}
	
	// MARK: User Actions
	func toggleRead(for item: Item) {
		try? queue.write {
			var newItem = item
			newItem.isRead.toggle()
			try newItem.update($0, columns: [Item.Column.isRead.rawValue])
		}
		Task { await sync.update(item) }
	}
	
	func toggleStarred(for item: Item) {
		try? queue.write {
			var newItem = item
			newItem.isStarred.toggle()
			try newItem.update($0, columns: [Item.Column.isStarred.rawValue])
		}
		Task { await sync.update(item) }
	}
	
	func delete(feed: Feed, sync: Bool = true) {
		try? queue.write { let _ = try feed.delete($0) }
		if sync {
			Task { await self.sync.delete(feed) }
		}
	}
	
	func fetch(source: URL? = nil, sync: Bool = true) {
		Task {
			do {
				// Fetch all feeds, if source is not defined and filter out feeds already being fetched
				let sources = try source.flatMap { [$0] } ?? (
					try queue.write {
						try Feed.fetchAll($0).map { $0.source }
					}
				).filter { !self.fetching.contains($0) }
				
				// Displays progress indicators
				DispatchQueue.main.async { self.fetching = self.fetching.union(Set(sources)) }
				for source in sources {
					Task {
						switch FeedParser(URL: source).parse() {
						case let .success(feed):
							try await queue.write {
								let mapped = Mapped(feed: feed, at: source)
								
								// 1. Feed: Insert on initial fetch
								if try self.isNewFeed(source: mapped.feed.source, $0) {
									try mapped.feed.insert($0)
									if sync {
										Task { await self.sync.add(mapped.feed) }
									}
								}
								
								// 2. Items: Merge fetched items with synced state (isRead, isStarred) and insert
								for var item in mapped.items {
									if let stored = try self.item(source: item.source, itemId: item.itemId, $0) {
										item.isRead = stored.isRead
										item.isStarred = stored.isStarred
										item.sync = stored.sync
										if stored == item { continue } // Skip unchanged items
									}
									try item.insert($0)
								}
								
								// 3. Insert attachements
								for attachment in mapped.attachments { try attachment.insert($0) }
							}
							DispatchQueue.main.async { self.fetching.remove(source) }
						case let .failure(parserError):
							DispatchQueue.main.async { self.fetching.remove(source) }
							throw parserError
						}
					}
				}
			} catch {
				// TODO: Surface import errors to user
				print("‼️ ", error)
			}
		}
	}

}
