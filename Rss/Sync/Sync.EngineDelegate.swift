import Foundation
import CloudKit
import os.log

extension Sync: CKSyncEngineDelegate {
	func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
		switch event {
		case let .stateUpdate(stateUpdate):
			stateSerialization = stateUpdate.stateSerialization
			Logger.sync.info("Updated State: \(stateUpdate.stateSerialization.rawValue.hash)")
			
		case let .fetchedDatabaseChanges(databaseChanges):
			for modification in databaseChanges.modifications {
				if let source = modification.zoneID.zoneName.url {
					if Store.shared.isNewFeed(source: source) {
						Logger.sync.info("New zone added: \(modification.zoneID.zoneName)")
						Store.shared.fetch(source: source, sync: false)
					}
				} else {
					Logger.sync.fault("Zone name not URL: \(modification.zoneID.zoneName)")
				}
			}
			for deletion in databaseChanges.deletions {
				if let source = deletion.zoneID.zoneName.url {
					Logger.sync.info("Received zone deletion: \(deletion.zoneID.zoneName)")
					Store.shared.delete(
						feed: Feed(source: source, title: nil, icon: nil),
						sync: false
					)
				} else {
					Logger.sync.fault("Zone name not URL: \(deletion.zoneID.zoneName)")
				}
			}
			
		case let .sentRecordZoneChanges(recordZoneChanges):
			for record in recordZoneChanges.savedRecords {
				if let item = Item.stored(with: record.recordID) {
					Store.shared.update(item: item.merged(with: record, mergeFields: false))
				} else {
					Logger.sync.fault("Sent record doesn't exist: \(record.recordID)")
				}
			}
			for failedRecordSave in recordZoneChanges.failedRecordSaves {
				switch failedRecordSave.error.code {
				case .serverRecordChanged:
					if let serverRecord = failedRecordSave.error.serverRecord,
					   let item = Item.stored(with: failedRecordSave.record.recordID) {
						Logger.sync.debug("Server record changed: \(failedRecordSave.record.recordID)")
						Store.shared.update(item: item.merged(with: serverRecord, mergeFields: true))
						update(item) // Queue changes in case the local record was newer
					} else {
						Logger.sync.fault("Missing server record or local item \(failedRecordSave.record.recordID)")
					}
				case .zoneNotFound, .unknownItem:
					Logger.sync.debug("Zone or record not found: \(failedRecordSave.record.recordID)")
					Store.shared.delete(
						feed: Feed(
							source: failedRecordSave.record.recordID.zoneID.zoneName.url!,
							title: nil,
							icon: nil
						)
					)
				case .networkFailure, .networkUnavailable, .zoneBusy, .serviceUnavailable, .notAuthenticated, .operationCancelled:
					// There are several errors that the sync engine will automatically retry, let's just log and move on.
					Logger.sync.debug("Will Retry: \(failedRecordSave.record.recordID): \(failedRecordSave.error)")
				default:
					Logger.sync.fault("Unknown error saving record \(failedRecordSave.record.recordID): \(failedRecordSave.error)")
				}
			}
			
		case let .fetchedRecordZoneChanges(recordZoneChanges):
			for modification in recordZoneChanges.modifications {
				Logger.sync.info("Received Item Update: \(modification.record.recordID)")
				if let item = Item.stored(with: modification.record.recordID) {
					Store.shared.update(item: item.merged(with: modification.record, mergeFields: true))
				} else {
					orphanedRecords.insert(modification.record)
				}
			}
			if !recordZoneChanges.deletions.isEmpty {
				Logger.sync.fault("Records should only be deleted with the zone")
			}
		default: Logger.sync.warning("🟢 \(event.description)")
		}
	}
	
	func nextRecordZoneChangeBatch(
		_ context: CKSyncEngine.SendChangesContext,
		syncEngine: CKSyncEngine
	) async -> CKSyncEngine.RecordZoneChangeBatch? {
		await CKSyncEngine.RecordZoneChangeBatch(
			pendingChanges: syncEngine.state.pendingRecordZoneChanges
				.filter { context.options.scope.contains($0) }
		) { recordID in
			Logger.sync.info("Dequeued record \(recordID.recordName)")
			return Item.stored(with: recordID)?.record
		}
	}
}
