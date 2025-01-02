import Foundation
import GRDB
import os.log

public protocol Storable:
	Hashable,
	Identifiable,
	Codable,
	FetchableRecord,
	PersistableRecord,
	Sendable { }

/// A class that provides a typed interface for all database operations
public final class Store: Sendable {
	let queue: DatabaseQueue
	let sync: SyncDelegate?
	
	/// - Parameter testName: Name, used in unit tests to create in memory database without sync
	public init(testName: String? = nil) throws {
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
		Task { await (sync as? Sync)?.start(store: self) }
	}
}

// TODO: Refactor after swift 6 migration
@MainActor
public class LoadingManager {
	@Observable
	public class Model {
		// TODO: Add failed state
		//	enum State {
		//		case ready, loading, failed
		//	}
		public var isLoading = false
	}
	
	public static let shared: LoadingManager = LoadingManager()
	
	private var models = Dictionary<URL, Model>()
	
	public func model(source: URL) -> Model {
		if let model = models[source] {
			return model
		} else {
			models[source] = Model()
			return model(source: source)
		}
	}
	
	func start(source: URL) {
		model(source: source).isLoading = true
	}
	
	func stop(source: URL) {
		model(source: source).isLoading = false
	}
}

