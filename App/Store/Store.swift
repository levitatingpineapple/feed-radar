import GRDB
import os.log
import NotificationCenter

protocol Storable: 
	Hashable,
	Identifiable,
	Codable,
	FetchableRecord,
	PersistableRecord { }

/// A class that provides a typed interface for all database operations
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
		try databaseMigrator.migrate(queue)
	}
}
