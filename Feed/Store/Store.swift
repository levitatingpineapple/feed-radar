import Foundation
import Combine
import FeedKit
import GRDB
import os.log
import NotificationCenter

protocol StoreDelegate {
	var feeds: Array<Feed> { get }
	func fetch(feed: Feed?) async
	func add(feed: Feed, userInitiated: Bool)
	func delete(feed: Feed, userInitiated: Bool)
	func deleteAllFeeds()
	
	var touchedItems: Array<Item> { get }
	func item(id: Item.ID) -> Item?
	func update(item: Item)
}

final class Store: ObservableObject, StoreDelegate {
//	static let shared = try! Store() // TODO: Environment object
	let queue: DatabaseQueue
	var sync: SyncDelegate?
	var lastFullFetch: TimeInterval?
	private var bag = Set<AnyCancellable>()
	
	@Published var filter: Filter?
	@Published var itemId: Item.ID?
	
	init(testName: String? = nil) throws {
		var configuration = Configuration()
		configuration.publicStatementArguments = true
		configuration.prepareDatabase {
			$0.trace {
				if $0.description.hasPrefix("PRAGMA") ||
				   $0.description.hasPrefix("BEGIN") ||
				   $0.description.hasPrefix("COMMIT") {
					return
				}
				Logger.store.trace("\($0.description)")
			}
		}
		
		if let testName {
			queue = try DatabaseQueue(named: testName, configuration: configuration)
		} else {
			queue = try DatabaseQueue(
				path: URL.documents.appendingPathComponent("feeds.db").path,
				configuration: configuration
			)
			sync = Sync(store: self)
		}
		
		try queue.write {
			try Feed.createTable(database: $0)
			try Item.createTable(database: $0)
			try Attachment.createTable(database: $0)
		}
		
		// Persist filter selection
		filter = UserDefaults.standard
			.data(forKey: .filterKey)
			.flatMap { Filter(rawValue: $0) }
		$filter
			.removeDuplicates()
			.sink { UserDefaults.standard.setValue($0?.rawValue, forKey: .filterKey) }
			.store(in: &bag)
		
		// Mark items as read as they are deselected
		$itemId
			.removeDuplicates()
			.scan((Optional<Item.ID>.none, Optional<Item.ID>.none)) { ($0.1, $1) }
			.sink { (deselected, selected) in
				if let deselected { self.markAsRead(id: deselected) }
			}
			.store(in: &bag)
		
		// Update unread badge
		Item.RequestCount(filter: Filter(isRead: false))
			.publisher(in: self)
			.replaceError(with: .zero)
			.sink { UNUserNotificationCenter.current().setBadgeCount($0) }
			.store(in: &bag)
	}
	
	func markAsRead(id: Item.ID) {
		if let item = self.item(id: id), item.isRead == false {
			self.toggleRead(for: item)
		}
	}
	
	func removeAttachments(id: Item.ID?) {
		try? queue.write {
			if let attachments = try? Attachment.filter(Attachment.Column.id.column == id).fetchAll($0) {
				attachments.forEach {
					try? FileManager.default.removeItem(at: $0.localUrl.deletingLastPathComponent())
					AttachhmentsFetcher.shared.tasks.removeValue(forKey: $0.url)
				}
			}
		}
	}
}
