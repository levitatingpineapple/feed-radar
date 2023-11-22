import Foundation
import FeedKit
import GRDB

enum Filter: Hashable {
	case all
	case feed(Feed)
}

class Store: ObservableObject {
	static let shared = try! Store()
	let queue: DatabaseQueue
	
	@Published var fetching = Set<URL>()
	@Published var filter: Filter?
	@Published var item: Item?
	
	init() throws {
		var configuration = Configuration()
		configuration.publicStatementArguments = true
		configuration.prepareDatabase {
			$0.trace {
				let string = String(describing: $0)
				switch string {
				case "BEGIN DEFERRED TRANSACTION": print("🟢")
				case "COMMIT TRANSACTION": print("🔴\n\n")
				default: print("⭐️", string)
				}
			}
		}
		queue = try DatabaseQueue(
			path: FileManager.default.urls(
				for: .documentDirectory,
				in: .userDomainMask
			).first!.appendingPathComponent("articles.db").path,
			configuration: configuration
		)
		try queue.write {
			try Feed.createTable(database: $0)
			try Item.createTable(database: $0)
			try Attachment.createTable(database: $0)
		}
	}
	
	func fetch(_ filter: Filter) {
		switch filter {
		case .all:
			do {
				let feeds = try queue
					.write { try Feed.fetchAll($0) }
					.filter { !fetching.contains($0.url) }
				self.fetching = Set<URL>(feeds.map { $0.url })
				feeds.forEach { fetch(feedUrl: $0.url) }
			} catch {
				
			}
		case let .feed(feed):
			if !fetching.contains(feed.url) {
				fetching.insert(feed.url)
				fetch(feedUrl: feed.url)
			}
		}
	}
	
	func fetch(feedUrl: URL) {
		Task {
			do {
				switch FeedParser(URL: feedUrl).parse() {
				case let .success(feed):
					try await queue.write { db in
						let mapped = Mapped(feed: feed, at: feedUrl)
						try mapped.feed.insert(db)
						for item in mapped.items { try item.insert(db) }
						for attachment in mapped.attachments { try attachment.insert(db) }
					}
					DispatchQueue.main.async { self.fetching.remove(feedUrl) }
				case let .failure(parserError):
					DispatchQueue.main.async { self.fetching.remove(feedUrl) }
					throw parserError
				}
			} catch {
				// TODO: Surface import errors to user
				print("‼️ ", error)
			}
		}
	}
	
	func delete(feed: Feed) {
		try? queue.write { let _ = try feed.delete($0) }
	}
}
