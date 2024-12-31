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
final class Store: Sendable {
	let queue: DatabaseQueue
	let sync: SyncDelegate?
	
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
			sync = nil
		} else {
			queue = try DatabaseQueue(path: URL.documents.appendingPathComponent("feeds.db").path)
			sync = Sync()
		}
		try databaseMigrator.migrate(queue)
		
		// TODO: Refactor after swift 6 migration
		Task { await (sync as? Sync)!.start(store: self) }
	}
}
