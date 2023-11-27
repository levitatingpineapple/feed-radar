import Foundation
import CloudKit
import SwiftUI
import os.log

actor Sync {
	var stateSerialization: CKSyncEngine.State.Serialization? {
		get {
			UserDefaults.standard.string(forKey: .cloudKitStateSerializationKey)
				.flatMap { CKSyncEngine.State.Serialization(rawValue: $0) }
		}
		set {
			UserDefaults.standard.setValue(
				newValue?.rawValue,
				forKey: .cloudKitStateSerializationKey
			)
		}
	}
	
	var syncEngine: CKSyncEngine!
	
	// Items that have been synced before they are fetched
	var orphanedRecords = Dictionary<URL, Set<CKRecord>>()

	init() {
		Task { await start() }
	}
	
	private func start() {
		let configuration = CKSyncEngine.Configuration(
			database: CKContainer(identifier: .cloudKitContainerIdentifier)
				.privateCloudDatabase,
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
		Logger.sync.info("Queue save record: \(item.recordID)")
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
