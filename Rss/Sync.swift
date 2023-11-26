import Foundation
import CloudKit
import SwiftUI

extension String {
	static let cloudKitContainerIdentifier = "iCloud.levitatingpineapple.todo"
	static let cloudKitStateSerializationKey = "cloudKitStateSerialization"
}

actor Sync {
	@AppStorage(.cloudKitStateSerializationKey)
	var stateSerialization: CKSyncEngine.State.Serialization?
	var syncEngine: CKSyncEngine!
	
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
}

extension Sync: CKSyncEngineDelegate {
	func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
		switch event {
		case let .stateUpdate(stateUpdate):
			stateSerialization = stateUpdate.stateSerialization
		default: break
		}
	}
	
	func nextRecordZoneChangeBatch(
		_ context: CKSyncEngine.SendChangesContext,
		syncEngine: CKSyncEngine
	) async -> CKSyncEngine.RecordZoneChangeBatch? {
		await CKSyncEngine.RecordZoneChangeBatch(
			pendingChanges: syncEngine.state.pendingRecordZoneChanges
		) { recordID in
			fatalError()
		}
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

extension Item {
	var record: CKRecord {
		let record = CKRecord(
			recordType: String(describing: self),
			recordID: CKRecord.ID(recordName: feedUrl.absoluteString + itemId)
		)
		record["isRead"] = isRead
		record["isStarred"] = isStarred
//		record["feed"]
		return record
	}
}
