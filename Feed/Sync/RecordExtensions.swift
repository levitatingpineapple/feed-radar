import Foundation
import CloudKit
import os.log

extension CKRecord {
	// Fetches local and merges it with the record, if it's newer.
	var mergedItem: Item? {
		if var item = Store.shared.item(id: recordID.itemId),
		   item.record.modificationDate ?? .distantPast < modificationDate ?? .distantFuture {
			let isRead = self[Item.Column.isRead.rawValue] as! Bool
			let isStarred = self[Item.Column.isStarred.rawValue] as! Bool
			Logger.sync.info("""
Merging (remote was newer) ✅ \(self.recordID.recordName)
	isRead: \(item.isRead.description) ---> \(isRead.description)
	isStarred: \(item.isStarred.description) ---> \(isStarred.description)
""")
			item.isRead = isRead
			item.isStarred = isStarred
			item.record = self
			return item
		} else {
			Logger.sync.info("Merging (remote was older) ❌ \(self.recordID.recordName)")
			return nil
		}
	}
}

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
