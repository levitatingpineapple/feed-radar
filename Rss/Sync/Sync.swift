import Foundation
import CloudKit
import SwiftUI
import os.log

actor Sync {
	@AppStorage(.cloudKitStateSerializationKey) var stateSerialization: CKSyncEngine.State.Serialization?
	var syncEngine: CKSyncEngine!
	var orphanedRecords = Set<CKRecord>()

	init() {
		Task { await start() }
	}
	
	private func start() {
		let configuration = CKSyncEngine.Configuration(
			database: CKContainer(identifier: .cloudKitContainerIdentifier).privateCloudDatabase,
			stateSerialization: stateSerialization,
			delegate: self
		)
		syncEngine = CKSyncEngine(configuration)
	}
	
	func add(_ feed: Feed) {
		Logger.sync.info("Queue add zone: \(feed.source.absoluteString)")
		syncEngine.state.add(
			pendingDatabaseChanges: [
				.saveZone(CKRecordZone(zoneName: feed.source.absoluteString))
			]
		)
	}
	
	func delete(_ feed: Feed) {
		Logger.sync.info("Queue delete zone: \(feed.source.absoluteString)")
		syncEngine.state.add(
			pendingDatabaseChanges: [
				.deleteZone(CKRecordZone.ID(zoneName: feed.source.absoluteString))
			]
		)
	}
	
	func update(_ item: Item) {
		Logger.sync.info("Queue record: \(item.recordID)")
		syncEngine.state.add(
			pendingRecordZoneChanges: [
				.saveRecord(item.recordID)
			]
		)
	}
}

extension CKSyncEngine.State.Serialization: RawRepresentable {
	public init?(rawValue: String) {
		if let data = rawValue.data(using: .utf8),
		   let result = try? JSONDecoder().decode(Self.self, from: data) {
			self = result
		} else {
			return nil
		}
	}
	
	public var rawValue: String {
		(try? JSONEncoder().encode(self))
			.flatMap { String(data: $0, encoding: .utf8) }
		?? String()
	}
}
