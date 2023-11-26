import Foundation
import Combine
import FeedKit
import GRDB

enum Download: Equatable {
	case progress(Double)
	case completed(URL)
	case error
}

class Store: ObservableObject {
	static let shared = try! Store()
	let queue: DatabaseQueue
	
	@Published var downloads = Dictionary<URL, Download>()
	@Published var fetching = Set<URL>()
	@Published var filter: Item.Filter?
	@Published var item: Item?
	
	private var bag = Set<AnyCancellable>()
	
	init() throws {
		var configuration = Configuration()
//		configuration.publicStatementArguments = true
//		configuration.prepareDatabase {
//			$0.trace {
//				let string = String(describing: $0)
//				switch string {
//				case "BEGIN DEFERRED TRANSACTION": print("🟢")
//				case "COMMIT TRANSACTION": print("🔴")
//				case "PRAGMA query_only = 1": break
//				case "PRAGMA query_only = 0": break
//				default: print("⭐️", string)
//				}
//			}
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
	
	func toggleRead(for item: Item) {
		try? self.queue.write {
			var newItem = item
			newItem.isRead.toggle()
			try newItem.update($0, columns: [Item.Column.isRead.rawValue])
		}
	}
	
	func toggleStarred(for item: Item) {
		try? self.queue.write {
			var newItem = item
			newItem.isStarred.toggle()
			try newItem.update($0, columns: [Item.Column.isStarred.rawValue])
		}
	}
	
	func fetch(feedUrl: URL? = nil) {
		Task {
			do {
				let feedUrls = try feedUrl.flatMap { [$0] } ?? (
					try queue.write {
						try Feed.order(Column(Feed.Column.title.rawValue)).fetchAll($0).map { $0.url }
					}
				).filter { !self.fetching.contains($0) }
				DispatchQueue.main.async { self.fetching = self.fetching.union(Set(feedUrls)) }
				for feedUrl in feedUrls {
					Task {
						switch FeedParser(URL: feedUrl).parse() {
						case let .success(feed):
							try await queue.write { db in
								let mapped = Mapped(feed: feed, at: feedUrl)
								try mapped.feed.insert(db)
								for var item in mapped.items {
									if let existing = try Item
										.filter(Column(Item.Column.feedUrl.rawValue) == item.feedUrl)
										.filter(Column(Item.Column.itemId.rawValue) == item.itemId)
										.fetchOne(db) {
										item.isRead = existing.isRead
										item.isStarred = existing.isStarred
										if existing == item { continue }
									}
									try item.insert(db)
								}
								for attachment in mapped.attachments { try attachment.insert(db) }
							}
							DispatchQueue.main.async { self.fetching.remove(feedUrl) }
						case let .failure(parserError):
							DispatchQueue.main.async { self.fetching.remove(feedUrl) }
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
	
	func delete(feed: Feed) {
		try? queue.write { let _ = try feed.delete($0) }
	}

	
	func download(attachment: Attachment) {
		if downloads.keys.contains(attachment.url) { return }
		var observation: NSKeyValueObservation!
		let dataTask = URLSession.shared.dataTask(with: URLRequest(url: attachment.url)) { data, _, _ in
			if let data {
				try! FileManager.default.createDirectory(
					at: attachment.localUrl.deletingLastPathComponent(),
					withIntermediateDirectories: true
				)
				try! data.write(to: attachment.localUrl)
				DispatchQueue.main.async {
					observation.invalidate()
					self.downloads[attachment.url] = .completed(attachment.localUrl)
				}
			} else {
				DispatchQueue.main.async {
					observation.invalidate()
					self.downloads[attachment.url] = .error
				}
			}
		}
		observation = dataTask.progress.observe(\.fractionCompleted) { progress, test in
			DispatchQueue.main.async {
				self.downloads[attachment.url] = .progress(progress.fractionCompleted)
			}
		}
		dataTask.resume()
	}
}
