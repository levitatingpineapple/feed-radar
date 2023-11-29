import Foundation
import CloudKit
import os.log

extension Sync: CKSyncEngineDelegate {
	func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
		switch event {
		case let .stateUpdate(event): stateUpdate(event)
		case let .accountChange(event): accountChange(event)
		case let .fetchedDatabaseChanges(event): fetchedDatabaseChanges(event)
		case let .fetchedRecordZoneChanges(event): fetchedRecordZoneChanges(event)
		case let .sentDatabaseChanges(event): sentDatabaseChanges(event)
		case let .sentRecordZoneChanges(event): sentRecordZoneChanges(event)
		case let .willFetchChanges(event): willFetchChanges(event)
		case let .willFetchRecordZoneChanges(event): willFetchRecordZoneChanges(event)
		case let .didFetchRecordZoneChanges(event): didFetchRecordZoneChanges(event)
		case let .didFetchChanges(event): didFetchChanges(event)
		case let .willSendChanges(event): willSendChanges(event)
		case let .didSendChanges(event): didSendChanges(event)
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
			Logger.sync.info("Dequeued record \(recordID.recordName)")
			return Item.stored(with: recordID)?.record
		}
	}
}

fileprivate extension Sync {
	func stateUpdate(_ stateUpdate: CKSyncEngine.Event.StateUpdate) {
		stateSerialization = stateUpdate.stateSerialization
		Logger.sync.info("Updated state. Hash: \(String(format:"%02X", stateUpdate.stateSerialization.rawValue.hash))")
	}
	
	func accountChange(_ accountChange: CKSyncEngine.Event.AccountChange) {
		switch accountChange.changeType {
		case .signIn:
			queueAll()
		case .switchAccounts, .signOut:
			Store.shared.deleteAllFeeds()
		@unknown default:
			Logger.sync.fault("Unknown account change type: \(accountChange)")
		}
	}
	
	func fetchedDatabaseChanges(_ fetchedDatabaseChanges: CKSyncEngine.Event.FetchedDatabaseChanges) {
		for modification in fetchedDatabaseChanges.modifications {
			if let source = modification.zoneID.zoneName.url {
				Logger.sync.info("New zone added: \(modification.zoneID.zoneName)")
				Store.shared.add(feed: Feed(source: source), userInitiated: false)
			} else {
				Logger.sync.fault("Zone name not URL: \(modification.zoneID.zoneName)")
			}
		}
		for deletion in fetchedDatabaseChanges.deletions {
			if let source = deletion.zoneID.zoneName.url {
				Logger.sync.info("Received zone deletion: \(deletion.zoneID.zoneName)")
				Store.shared.delete(feed: Feed(source: source), userInitiated: false)
			} else {
				Logger.sync.fault("Zone name not URL: \(deletion.zoneID.zoneName)")
			}
		}
	}
	
	func fetchedRecordZoneChanges(_ fetchedRecordZoneChanges: CKSyncEngine.Event.FetchedRecordZoneChanges) {
		for modification in fetchedRecordZoneChanges.modifications {
			Logger.sync.info("Received Item Update: \(modification.record.recordID)")
			if let item = Item.stored(with: modification.record.recordID) {
				Store.shared.update(item: item.merged(with: modification.record, mergeFields: true))
			} else {
				orphanedRecords.insert(modification.record)
			}
		}
		if !fetchedRecordZoneChanges.deletions.isEmpty {
			Logger.sync.fault("Records should only be deleted with the zone")
		}
	}
	
	func sentDatabaseChanges(_ sentDatabaseChanges: CKSyncEngine.Event.SentDatabaseChanges) {
		Logger.sync.debug("Sent database changes")
	}
	
	func sentRecordZoneChanges(_ sentRecordZoneChanges: CKSyncEngine.Event.SentRecordZoneChanges) {
		for record in sentRecordZoneChanges.savedRecords {
			if let item = Item.stored(with: record.recordID) {
				Store.shared.update(item: item.merged(with: record, mergeFields: false))
			} else {
				Logger.sync.info("Sent record doesn't exist: \(record.recordID)")
			}
		}
		for failedRecordSave in sentRecordZoneChanges.failedRecordSaves {
			switch failedRecordSave.error.code {
			case .serverRecordChanged:
				if let serverRecord = failedRecordSave.error.serverRecord,
				   let item = Item.stored(with: failedRecordSave.record.recordID) {
					Logger.sync.error("Server record changed, merging remote changes: \(failedRecordSave.record.recordID)")
					Store.shared.update(item: item.merged(with: serverRecord, mergeFields: true))
					queueUpdated(item)
				} else {
					Logger.sync.info("Missing server record or local item \(failedRecordSave.record.recordID)")
				}
			case .zoneNotFound, .unknownItem:
				Logger.sync.info("Zone or record not found. Deleting local feed: \(failedRecordSave.record.recordID.zoneID)")
				Store.shared.delete(
					feed: Feed(
						source: failedRecordSave.record.recordID.zoneID.zoneName.url!,
						title: nil,
						icon: nil
					)
				)
			case .networkFailure, .networkUnavailable, .zoneBusy, .serviceUnavailable, .notAuthenticated, .operationCancelled:
				Logger.sync.error("Will Retry: \(failedRecordSave.record.recordID): \(failedRecordSave.error)")
			default:
				Logger.sync.fault("Unhandled error saving record \(failedRecordSave.record.recordID): \(failedRecordSave.error)")
			}
		}
	}
	
	func willFetchChanges(_ willFetchChanges: CKSyncEngine.Event.WillFetchChanges) {
		Logger.sync.debug("Will fetch changes")
	}

	func willFetchRecordZoneChanges(_ willFetchRecordZoneChanges: CKSyncEngine.Event.WillFetchRecordZoneChanges) {
		Logger.sync.debug("Will fetch record zone changes")
	}

	func didFetchRecordZoneChanges(_ didFetchRecordZoneChanges: CKSyncEngine.Event.DidFetchRecordZoneChanges) {
		Logger.sync.debug("Did fetch record zone changes")
	}

	func didFetchChanges(_ didFetchChanges: CKSyncEngine.Event.DidFetchChanges) {
		Logger.sync.debug("Did fetch changes")
	}

	func willSendChanges(_ willSendChanges: CKSyncEngine.Event.WillSendChanges) {
		Logger.sync.debug("Will send changes")
	}

	func didSendChanges(_ didSendChanges: CKSyncEngine.Event.DidSendChanges) {
		Logger.sync.debug("Did send changes")
	}
}
