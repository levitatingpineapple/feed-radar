import Foundation
import FeedKit
import GRDB


enum Filter: Hashable {
	case all
	case feed(Feed)
}

class Store {
	static let shared = try! Store()
	let queue: DatabaseQueue
	
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
			print("TODO")
		case let .feed(feed):
			fetch(url: feed.url)
		}
	}
	
	func fetch(url: URL) {
		Task {
			do {
				switch FeedParser(URL: url).parse() {
				case let .success(feed):
					try await queue.write { db in
						let mapped = Mapped(feed: feed, at: url)
						try mapped.feed.insert(db)
						for item in mapped.items { try item.insert(db) }
						for attachment in mapped.attachments { try attachment.insert(db) }
					}
				case let .failure(parserError):
					throw parserError
				}
			} catch {
				print("‼️ ", error)
			}
		}
	}
}
