import Foundation
import CloudKit
import os.log

extension Item {
	var recordID: CKRecord.ID {
		CKRecord.ID(
			recordName: itemId,
			zoneID: CKRecordZone.ID(zoneName: source.absoluteString)
		)
	}
	
	var record: CKRecord {
		get {
			let record = sync.flatMap {
				if let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: $0) {
					unarchiver.requiresSecureCoding = true
					return CKRecord(coder: unarchiver)
				} else {
					Logger.sync.fault("Clould not decode record for \(itemId)")
					return .none
				}
			} ?? CKRecord(
				recordType: String(describing: Item.self),
				recordID: recordID
			)
			record["isRead"] = isRead
			record["isStarred"] = isStarred
			return record
		}
		set {
			let archiver = NSKeyedArchiver(requiringSecureCoding: true)
			newValue.encodeSystemFields(with: archiver)
			sync = archiver.encodedData
		}
	}
	
	func merged(with remoteRecord: CKRecord, mergeFields: Bool) -> Item {
		var merged = self
		if mergeFields {
			merged.isRead = remoteRecord["isRead"] as! Bool
			merged.isStarred = remoteRecord["isStarred"] as! Bool
			Logger.sync.info("Item fields updated from remote, ItemId: \(itemId)")
		}
		if merged.record.modificationDate ?? .distantPast <
		   remoteRecord.modificationDate ?? .distantFuture {
			merged.record = remoteRecord
			Logger.sync.info("Item record updated from remote. ItemId: \(itemId)")
		} else {
			Logger.sync.info("Remote record older and discarded. ItemId: \(itemId)")
		}
		return merged
	}
	
	static func stored(with recordID: CKRecord.ID) -> Item? {
		recordID.zoneID.zoneName.url
			.flatMap { Store.shared.item(source: $0, itemId: recordID.recordName) }
	}
}
