import CloudKit
import os.log

extension CKRecordZone.ID {
	/// Feed's `source` is stored in the `zoneName`.
	var source: URL { URL(string: zoneName)! }
}

extension CKRecord.ID {
	/// `recordName` holds item's `id` encoded as hexadecimal string.
	var itemId: Item.ID { Int64(recordName, radix: 16)! }
	/// Item's `source` is stored in the `zoneName`.
	var source: URL { zoneID.source }
}

extension Feed {
	/// Feed's corresponding `CKRecordZone.ID`.
	var zoneID: CKRecordZone.ID { CKRecordZone.ID(zoneName: source.absoluteString) }
	/// Feed's corresponding `CKRecordZone`.
	var zone: CKRecordZone { CKRecordZone(zoneID: zoneID) }
}

extension Item {
	/// Feed's corresponding `CKRecord.ID`.
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
