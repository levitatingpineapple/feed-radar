import CloudKit
import os.log

extension CKRecordZone.ID {
	var source: URL { URL(string: zoneName)! }
}

extension CKRecord.ID {
	var itemId: Item.ID { Int64(recordName, radix: 16)! }
	var source: URL { zoneID.source }
}

extension Feed {
	var zoneID: CKRecordZone.ID { CKRecordZone.ID(zoneName: source.absoluteString) }
	var zone: CKRecordZone { CKRecordZone(zoneID: zoneID) }
}

extension Item {
	var recordID: CKRecord.ID {
		CKRecord.ID(
			recordName: String(format: "%llx", id),
			zoneID: Feed(source: source).zoneID
		)
	}
	
	/// Item's corresponding `CKRecord`
	/// They are persisted in the database.\
	/// If no record is found, a new one is created.
	var record: CKRecord {
		get {
			let record = sync.flatMap {
				if let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: $0) {
					unarchiver.requiresSecureCoding = true
					return CKRecord(coder: unarchiver)
				} else {
					Logger.sync.fault("Clould not decode record for \(id)")
					return .none
				}
			} ?? CKRecord(
				recordType: String(describing: Item.self),
				recordID: recordID
			)
			record[Column.isRead.rawValue] = isRead
			record[Column.isStarred.rawValue] = isStarred
			return record
		}
		set {
			let archiver = NSKeyedArchiver(requiringSecureCoding: true)
			newValue.encodeSystemFields(with: archiver)
			sync = archiver.encodedData
		}
	}
}
