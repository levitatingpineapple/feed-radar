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
			Logger.sync.info("Decoded record: \(record), isRead: \(isRead), (isStarred: \(isStarred)")
			return record
		}
		set {
			let archiver = NSKeyedArchiver(requiringSecureCoding: true)
			newValue.encodeSystemFields(with: archiver)
			Logger.sync.info("Decoded record: \(newValue)")
			sync = archiver.encodedData
		}
	}
}
