import Foundation
import CloudKit
import os.log

extension Sync: CKSyncEngineDelegate {
	func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
		switch event {
		case .stateUpdate(let event): stateUpdate(event)
		case .accountChange(let event): accountChange(event)
		case .fetchedDatabaseChanges(let event): fetchedDatabaseChanges(event)
		case .fetchedRecordZoneChanges(let event): fetchedRecordZoneChanges(event)
		case .sentDatabaseChanges: Logger.sync.debug("Sent database changes")
		case .sentRecordZoneChanges(let event): sentRecordZoneChanges(event)
		case .willFetchChanges: Logger.sync.debug("Will fetch changes")
		case .willFetchRecordZoneChanges: Logger.sync.debug("Will fetch record zone changes")
		case .didFetchRecordZoneChanges: Logger.sync.debug("Did fetch record zone changes")
		case .didFetchChanges: Logger.sync.debug("Did fetch changes")
		case .willSendChanges: Logger.sync.debug("Will send changes")
		case .didSendChanges: Logger.sync.debug("Did send changes")
		@unknown default: Logger.sync.fault("Unexpected sync event")
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
			Logger.sync.info("Dequeued \(recordID.recordName)")
			return Item.stored(with: recordID)?.record
		}
	}
}

fileprivate extension Sync {
	func stateUpdate(_ stateUpdate: CKSyncEngine.Event.StateUpdate) {
		stateSerialization = stateUpdate.stateSerialization
		Logger.sync.info("Updated state. Hash: \(stateUpdate)")
	}
	
	func accountChange(_ accountChange: CKSyncEngine.Event.AccountChange) {
		switch accountChange.changeType {
		case .signIn:
			queueAll()
		case .switchAccounts, .signOut:
			Store.shared.deleteAllFeeds()
		 default:
			Logger.sync.fault("Unknown account change type: \(accountChange)")
		}
	}
	
	func fetchedDatabaseChanges(_ fetchedDatabaseChanges: CKSyncEngine.Event.FetchedDatabaseChanges) {
		for modification in fetchedDatabaseChanges.modifications {
			Logger.sync.info("New zone added: \(modification.zoneID)")
			Store.shared.add(feed: Feed(source: modification.zoneID.source), userInitiated: false)
		}
		for deletion in fetchedDatabaseChanges.deletions {
			Logger.sync.info("Received zone deletion: \(deletion.zoneID)")
			Store.shared.delete(feed: Feed(source: deletion.zoneID.source), userInitiated: false)
		}
	}
	
	func fetchedRecordZoneChanges(_ fetchedRecordZoneChanges: CKSyncEngine.Event.FetchedRecordZoneChanges) {
		for modification in fetchedRecordZoneChanges.modifications {
			if let item = Item.stored(with: modification.record.recordID) {
				Logger.sync.info("Received item update: \(modification.record.recordID)")
				if let merged =  item.merged(with: modification.record) {
					Store.shared.update(item: merged)
				}
			} else {
				Logger.sync.info("Received item update, no matching local item: \(modification.record.recordID)")
				orphanedRecords.insert(modification.record)
				Store.shared.fetch(feed: Feed(source: modification.record.recordID.source))
			}
		}
		if !fetchedRecordZoneChanges.deletions.isEmpty {
			Logger.sync.fault("Records should only be deleted with the zone")
		}
	}
	
	func sentRecordZoneChanges(_ sentRecordZoneChanges: CKSyncEngine.Event.SentRecordZoneChanges) {
		for savedRecord in sentRecordZoneChanges.savedRecords {
			if let item = Item.stored(with: savedRecord.recordID),
			   let merged = item.merged(with: savedRecord) {
				Logger.sync.info("Merging sent record: \(savedRecord.recordID)")
				Store.shared.update(item: merged)
			} else {
				Logger.sync.info("Sent record doesn't exist: \(savedRecord.recordID)")
			}
		}
		for failedRecordSave in sentRecordZoneChanges.failedRecordSaves {
			switch failedRecordSave.error.code {
			case .serverRecordChanged:
				if let serverRecord = failedRecordSave.error.serverRecord,
				   let item = Item.stored(with: failedRecordSave.record.recordID),
				   let merged = item.merged(with: serverRecord) {
					Logger.sync.error("Server record changed, merging remote changes: \(failedRecordSave.record.recordID)")
					Store.shared.update(item: merged)
					queueUpdated(item)
				} else {
					Logger.sync.fault("Missing server record or local item \(failedRecordSave.record.recordID)")
				}
			case .zoneNotFound, .unknownItem:
				Logger.sync.info("Zone or record not found. Deleting local feed: \(failedRecordSave.record.recordID.zoneID)")
				Store.shared.delete(
					feed: Feed(source: failedRecordSave.record.recordID.source)
				)
			case .networkFailure, .networkUnavailable, .zoneBusy, .serviceUnavailable, .notAuthenticated, .operationCancelled:
				Logger.sync.error("Will Retry: \(failedRecordSave.record.recordID): \(failedRecordSave.error)")
			default:
				Logger.sync.fault("Unhandled error saving record \(failedRecordSave.record.recordID): \(failedRecordSave.error)")
			}
		}
	}
}
