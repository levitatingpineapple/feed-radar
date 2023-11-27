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
				Logger.sync.info("Received zone modification: \(modification.zoneID.zoneName)")
				if let source = modification.zoneID.zoneName.url,
				   Store.shared.isNewFeed(source: source) {
					Store.shared.fetch(source: source, sync: false)
				}
			}
			for deletion in databaseChanges.deletions {
				Logger.sync.info("Received zone deletion: \(deletion.zoneID.zoneName)")
				Store.shared.delete(
					feed: Feed(source: deletion.zoneID.zoneName.url!, title: nil, icon: nil),
					sync: false
				)
			}
			
		case let .sentRecordZoneChanges(recordZoneChanges):
			for record in recordZoneChanges.savedRecords {
				if var localItem = Store.shared.item(
					source: record.recordID.zoneID.zoneName.url!,
					itemId: record.recordID.recordName
				) {
					if let remoteDate = record.modificationDate,
					   localItem.record.modificationDate ?? .distantPast < remoteDate {
						localItem.record = record
						Logger.sync.info("Item record updated: \(record.recordID.recordName)")
					}
					Store.shared.update(item: localItem)
				}
			}
			
			for failedRecordSave in recordZoneChanges.failedRecordSaves {
				print("‼️‼️‼️‼️‼️‼️‼️‼️‼️", failedRecordSave.error)
			}
			
		case let .fetchedRecordZoneChanges(recordZoneChanges):
			for modification in recordZoneChanges.modifications {
				Logger.sync.info("Received item modification: \(modification.record.recordID)")
				
				if var localItem = Store.shared.item(
					source: modification.record.recordID.zoneID.zoneName.url!,
					itemId: modification.record.recordID.recordName
				) {
					localItem.isRead = modification.record["isRead"] as! Bool
					localItem.isStarred = modification.record["isStarred"] as! Bool
					if let remoteDate = modification.record.modificationDate,
					   localItem.record.modificationDate ?? .distantPast < remoteDate {
						localItem.record = modification.record
						Logger.sync.info("Item record updated: \(modification.record.recordID.recordName)")
					}
					Store.shared.update(item: localItem)
				} else {
					
					// TODO: Add to transientRecords
				}
				// If item exists - merge data
				// If not - the item might not be fetched yet - put it in the orphaned set,
				// that will be cleared after next fetch
			}
			guard recordZoneChanges.deletions.isEmpty else {
				fatalError("Records should only be deleted with the zone")
			}
		default: Logger.sync.warning("🟢 \(event.description)")
		}
	}
	
	func nextRecordZoneChangeBatch(
		_ context: CKSyncEngine.SendChangesContext,
		syncEngine: CKSyncEngine
	) async -> CKSyncEngine.RecordZoneChangeBatch? {
		await CKSyncEngine.RecordZoneChangeBatch(
			pendingChanges: syncEngine.state
				.pendingRecordZoneChanges
				.filter { context.options.scope.contains($0) }
		) { recordID in
			Store.shared.item(
				source: recordID.zoneID.zoneName.url!,
				itemId: recordID.recordName
			)?.record
		}
	}
}
