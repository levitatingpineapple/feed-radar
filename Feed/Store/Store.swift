import Foundation
import Combine
import FeedKit
import GRDB
import os.log
import NotificationCenter

class Store: ObservableObject {
	let queue: DatabaseQueue
	static let shared = try! Store() // TODO: Inject as environment object
	let sync = Sync()
	private var bag = Set<AnyCancellable>()
	
	@Published var filter: Item.Filter?
	@Published var item: Item?
	
	init() throws {
		var configuration = Configuration()
		configuration.publicStatementArguments = true
		configuration.prepareDatabase {
			$0.trace { Logger.store.trace("\($0.description)") }
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
		
		// Persist last used filter
		filter = UserDefaults.standard
			.data(forKey: .filterKey)
			.flatMap { Item.Filter(rawValue: $0) }
		$filter
			.removeDuplicates()
			.sink { UserDefaults.standard.setValue($0?.rawValue, forKey: .filterKey) }
			.store(in: &bag)
		
		// Mark deselected items as read
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
		
		// Update unread badge
		Item.RequestCount(filter: Item.Filter(isRead: false))
			.publisher(in: self)
			.replaceError(with: .zero)
			.sink { UNUserNotificationCenter.current().setBadgeCount($0) }
			.store(in: &bag)
	}
	
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
					AttachhmentsFetcher.shared.tasks.removeValue(forKey: $0.url)
				}
			}
		}
	}
}
