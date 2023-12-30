import Foundation
import GRDB
import os.log
import NotificationCenter

final class Store {
	let queue: DatabaseQueue
	var sync: SyncDelegate?
	var lastFullFetch: TimeInterval?
	
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
	}
}
