import Foundation
import GRDB
import os.log
import NotificationCenter

/// A class that is responsible for all database operations
final class Store {
	let queue: DatabaseQueue
	var sync: SyncDelegate?
	
	/// Last time when all feeds were fetched, since the app launch
	var lastFullFetch: TimeInterval?
	
	/// - Parameter testName: Name, used in unit tests to create in memory database without sync
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
