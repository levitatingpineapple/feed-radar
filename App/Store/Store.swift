import Foundation
import GRDB
import os.log

protocol Storable: 
	Hashable,
	Identifiable,
	Codable,
	FetchableRecord,
	PersistableRecord { }

/// A class that provides a typed interface for all database operations
final class Store {
	let queue: DatabaseQueue
	let fetcher = FeedFetcher()
	var sync: SyncDelegate?
	/// Last time when all feeds were fetched, since the app launch
	var lastFullFetch: TimeInterval?
	
	/// - Parameter testName: Name, used in unit tests to create in memory database without sync
	init(testName: String? = nil) throws {
		if let testName {
			var configuration = Configuration()
			configuration.publicStatementArguments = true
			configuration.prepareDatabase {
				$0.trace { Logger.store.trace("\($0.description)") }
			}
			configuration.qos = .background
			queue = try DatabaseQueue(named: testName, configuration: configuration)
		} else {
			queue = try DatabaseQueue(path: URL.documents.appendingPathComponent("feeds.db").path)
			sync = Sync(store: self)
		}
		try databaseMigrator.migrate(queue)
	}
}
