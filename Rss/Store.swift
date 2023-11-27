import Foundation
import Combine
import FeedKit
import GRDB
import os.log

enum Download: Equatable {
	case progress(Double)
	case completed(URL)
	case error
}

class Store: ObservableObject {
	static let shared = try! Store()
	let queue: DatabaseQueue
	let sync = Sync()
	
	@Published var downloads = Dictionary<URL, Download>()
	@Published var fetching = Set<URL>()
	@Published var filter: Item.Filter?
	@Published var item: Item?
	
	private var bag = Set<AnyCancellable>()
	
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
	
	func item(source: URL, itemId: String) -> Item? {
		try? queue.write {
			try Item
				.filter(Column(Item.Column.source.rawValue) == source)
				.filter(Column(Item.Column.itemId.rawValue) == itemId)
				.fetchOne($0)
		}
	}
	
	func isNewFeed(source: URL) -> Bool {
		(try? queue.write {
			try Feed
				.filter(Column(Item.Column.source.rawValue) == source)
				.isEmpty($0)
		}) ?? true
	}
 
	func update(item: Item) {
		try? queue.write {
			try item.insert($0)
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
				
				// Display progress indicators
				DispatchQueue.main.async { self.fetching = self.fetching.union(Set(sources)) }
				for source in sources {
					Task {
						switch FeedParser(URL: source).parse() {
						case let .success(feed):
							try await queue.write {
								let mapped = Mapped(feed: feed, at: source)
								
								// Insert and sync feed, if it does not exist
								if try Feed
									.filter(Column(Feed.Column.source.rawValue) == mapped.feed.source)
									.isEmpty($0) {
									try mapped.feed.insert($0)
									if sync {
										Task { await self.sync.add(mapped.feed) }
									}
								}
								
								// Merge fetched items with synced state (isRead, isStarred) and insert
								for var item in mapped.items {
									if let existing = try Item
										.filter(Column(Item.Column.source.rawValue) == item.source)
										.filter(Column(Item.Column.itemId.rawValue) == item.itemId)
										.fetchOne($0) {
										item.isRead = existing.isRead
										item.isStarred = existing.isStarred
										if existing == item { continue }
									}
									try item.insert($0)
								}
								
								// Insert attachements
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
	
	func delete(feed: Feed, sync: Bool = true) {
		try? queue.write { let _ = try feed.delete($0) }
		if sync {
			Task { await self.sync.delete(feed) }
		}
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
