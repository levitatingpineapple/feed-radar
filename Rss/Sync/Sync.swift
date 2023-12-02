import Foundation
import CloudKit
import SwiftUI
import os.log

actor Sync {
	var syncEngine: CKSyncEngine!
	var orphanedRecords = Set<CKRecord>()
	var stateSerialization: CKSyncEngine.State.Serialization? {
		get {
			if let data = UserDefaults.standard.data(forKey: .cloudKitStateSerializationKey),
			   let result = try? JSONDecoder().decode(
				CKSyncEngine.State.Serialization.self,
				from: data
			) { result } else { nil }
		}
		set {
			UserDefaults.standard.setValue(
				try! JSONEncoder().encode(newValue),
				forKey: .cloudKitStateSerializationKey
			)
		}
	}

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
	
	func processOrphanedRecords(for feed: Feed) {
		orphanedRecords
			.filter { $0.recordID.source == feed.source }
			.forEach { orphanedRecord in
				if let mergedItem = orphanedRecord.mergedItem {
					Logger.sync.info("Merging orphaned record: \(orphanedRecord.recordID)")
					Store.shared.update(item: mergedItem)
				}
			}
	}
	
	func queueAll() {
		Logger.sync.info("Queue all")
		syncEngine.state.add(
			pendingDatabaseChanges: Store.shared.feeds
				.map { .saveZone($0.zone) }
		)
		syncEngine.state.add(
			pendingRecordZoneChanges: Store.shared.touchedItems
				.map { .saveRecord($0.recordID) }
		)
	}
	
	func queueAdded(_ feed: Feed) {
		Logger.sync.info("Queue add zone: \(feed.zone)")
		syncEngine.state.add(
			pendingDatabaseChanges: [ .saveZone(feed.zone) ]
		)
	}
	
	func queueDeleted(_ feed: Feed) {
		Logger.sync.info("Queue delete zone: \(feed.zoneID)")
		syncEngine.state.add(
			pendingDatabaseChanges: [ .deleteZone(feed.zoneID) ]
		)
	}
	
	func queueUpdated(_ item: Item) {
		Logger.sync.info("Queue record: \(item.recordID)")
		syncEngine.state.add(
			pendingRecordZoneChanges: [
				.saveRecord(item.recordID)
			]
		)
	}
}
