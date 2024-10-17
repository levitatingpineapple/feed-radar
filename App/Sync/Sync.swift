import CloudKit
import os.log

/// Sync interface. Currently only CloudKit sync is implemented.
protocol SyncDelegate: Actor {
	
	/// User has added a new feed
	func added(_ feed: Feed)
	
	/// User has deleted a feed
	func deleted(_ feed: Feed)
	
	/// A state of an item has been changed
	func updated(_ item: Item)
	
	/// If received changes does not yet have a corresponding item they become orphaned.\
	/// Store will call this function after fetching a feed, to apply retained changes.
	func processOrphanedRecords(for feed: Feed)
}

/// A class that handles syncing using CloudKit
/// Implements ``SyncDelegate``
final actor Sync {
	fileprivate let itemUpdateBatcher: ItemUpdateBatcher
	fileprivate let store: Store
	fileprivate var engine: CKSyncEngine!
	fileprivate var orphanedRecords = Set<CKRecord>()
	fileprivate var stateSerialization: CKSyncEngine.State.Serialization? {
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
	
	/// Creates an instance of ``Sync``
	/// - Parameter store: For storing incomming changes
	init(store: Store) {
		self.store = store
		self.itemUpdateBatcher = ItemUpdateBatcher(store: store)
		Task { await start() }
	}
	
	private func start() {
		let configuration = CKSyncEngine.Configuration(
			database: CKContainer.default().privateCloudDatabase,
			stateSerialization: stateSerialization,
			delegate: self
		)
		engine = CKSyncEngine(configuration)
	}
	
	/// Returns an updated item, if the record it's merged with was newer.
	fileprivate func mergedItem(_ remote: CKRecord) -> Item? {
		if var item = store.item(id: remote.recordID.itemId),
		   item.record.modificationDate ?? .distantPast < remote.modificationDate ?? .distantFuture {
			let isRead = remote[Item.Column.isRead.rawValue] as! Bool
			let isStarred = remote[Item.Column.isStarred.rawValue] as! Bool
			Logger.sync.info("""
Merging (remote was newer) ✅ \(remote.recordID.recordName)
	isRead: \(item.isRead.description) ---> \(isRead.description)
	isStarred: \(item.isStarred.description) ---> \(isStarred.description)
""")
			item.isRead = isRead
			item.isStarred = isStarred
			item.record = remote
			return item
		} else {
			Logger.sync.info("Merging (remote was older) ❌ \(remote.recordID.recordName)")
			return nil
		}
	}
}

// MARK: Sync Delegate

extension Sync: SyncDelegate {
	func added(_ feed: Feed) {
		Logger.sync.info("Queue add zone: \(feed.zone)")
		engine.state.add(
			pendingDatabaseChanges: [ .saveZone(feed.zone) ]
		)
	}
	
	func deleted(_ feed: Feed) {
		Logger.sync.info("Queue delete zone: \(feed.zoneID)")
		engine.state.add(
			pendingDatabaseChanges: [ .deleteZone(feed.zoneID) ]
		)
	}
	
	func updated(_ item: Item) {
		Logger.sync.info("Queue record: \(item.recordID)")
		engine.state.add(
			pendingRecordZoneChanges: [
				.saveRecord(item.recordID)
			]
		)
	}
	
	func processOrphanedRecords(for feed: Feed) {
		orphanedRecords
			.filter { $0.recordID.source == feed.source }
			.forEach { orphanedRecord in
				if let mergedItem = mergedItem(orphanedRecord) {
					Logger.sync.info("Merging orphaned record: \(orphanedRecord.recordID)")
					store.update(item: mergedItem)
				}
			}
	}
}

// MARK: Engine Delegate

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
			return await store.item(id: recordID.itemId)?.record
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
			engine.state.add(
				pendingDatabaseChanges: store.feeds.map { .saveZone($0.zone) }
			)
			engine.state.add(
				pendingRecordZoneChanges: store.touchedItems.map { .saveRecord($0.recordID) }
			)
		case .switchAccounts, .signOut:
			store.clearAllData()
		 default:
			Logger.sync.fault("Unknown account change type: \(accountChange)")
		}
	}
	
	func fetchedDatabaseChanges(_ fetchedDatabaseChanges: CKSyncEngine.Event.FetchedDatabaseChanges) {
		for modification in fetchedDatabaseChanges.modifications {
			Logger.sync.info("New zone added: \(modification.zoneID)")
			Task { await store.add(feed: Feed(source: modification.zoneID.source), userInitiated: false) }
		}
		for deletion in fetchedDatabaseChanges.deletions {
			Logger.sync.info("Received zone deletion: \(deletion.zoneID)")
			store.delete(feed: Feed(source: deletion.zoneID.source), userInitiated: false)
		}
	}
	
	func fetchedRecordZoneChanges(_ fetchedRecordZoneChanges: CKSyncEngine.Event.FetchedRecordZoneChanges) {
		for modification in fetchedRecordZoneChanges.modifications {
			Logger.sync.info("Received item update: \(modification.record.recordID)")
			if let mergedItem = mergedItem(modification.record) {
				itemUpdateBatcher.update(item: mergedItem)
			} else {
				Logger.sync.info("Received item update, no matching local item: \(modification.record.recordID)")
				orphanedRecords.insert(modification.record)
				Task { await store.fetch(feed: Feed(source: modification.record.recordID.source)) }
			}
		}
		if !fetchedRecordZoneChanges.deletions.isEmpty {
			Logger.sync.fault("Records should only be deleted with the zone")
		}
	}
	
	func sentRecordZoneChanges(_ sentRecordZoneChanges: CKSyncEngine.Event.SentRecordZoneChanges) {
		for savedRecord in sentRecordZoneChanges.savedRecords {
			if let mergedItem = mergedItem(savedRecord) {
				Logger.sync.info("Merging sent record: \(savedRecord.recordID)")
				store.update(item: mergedItem)
			} else {
				Logger.sync.info("Sent record doesn't exist: \(savedRecord.recordID)")
			}
		}
		for failedRecordSave in sentRecordZoneChanges.failedRecordSaves {
			switch failedRecordSave.error.code {
			case .serverRecordChanged:
				if let serverRecord = failedRecordSave.error.serverRecord,
				   let mergedItem = mergedItem(serverRecord) {
					Logger.sync.error("Server record changed, merging remote changes: \(failedRecordSave.record.recordID)")
					store.update(item: mergedItem)
					updated(mergedItem)
				} else {
					Logger.sync.fault("Missing server record or local item \(failedRecordSave.record.recordID)")
				}
			case .zoneNotFound, .unknownItem:
				Logger.sync.info("Zone or record not found. Deleting local feed: \(failedRecordSave.record.recordID.zoneID)")
				store.delete(
					feed: Feed(source: failedRecordSave.record.recordID.source),
					userInitiated: false
				)
			case .networkFailure, .networkUnavailable, .zoneBusy, .serviceUnavailable, .notAuthenticated, .operationCancelled:
				Logger.sync.error("Will Retry: \(failedRecordSave.record.recordID): \(failedRecordSave.error)")
			default:
				Logger.sync.fault("Unhandled error saving record \(failedRecordSave.record.recordID): \(failedRecordSave.error)")
			}
		}
	}
}
