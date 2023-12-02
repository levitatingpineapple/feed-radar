import Foundation
import CloudKit
import os.log

extension CKRecordZone.ID {
	var source: URL { URL(string: zoneName.strippingPrefix(.cloudKitZoneIdPrefix))! }
}

extension CKRecord.ID {
	var itemId: String { recordName.strippingPrefix(.cloudKitRecordIdPrefix) }
	var source: URL { zoneID.source }
}

extension Feed {
	var zoneID: CKRecordZone.ID {
		CKRecordZone.ID(zoneName: .cloudKitZoneIdPrefix + source.absoluteString)
	}
	
	var zone: CKRecordZone { CKRecordZone(zoneID: zoneID) }
}

extension Item {
	var recordID: CKRecord.ID {
		CKRecord.ID(
			recordName: .cloudKitRecordIdPrefix + itemId,
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
					Logger.sync.fault("Clould not decode record for \(itemId)")
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


extension CKRecord {
	// Fetches local and merges it with the record, if it's newer.
	var mergedItem: Item? {
		if var item = Store.shared.item(source: recordID.zoneID.source, itemId: recordID.itemId),
		   item.record.modificationDate ?? .distantPast < modificationDate ?? .distantFuture {
			let isRead = self[Item.Column.isRead.rawValue] as! Bool
			let isStarred = self[Item.Column.isStarred.rawValue] as! Bool
			Logger.sync.info("""
Merging (remote was newer) ✅ \(self.recordID.itemId)
	isRead: \(item.isRead.description) ---> \(isRead.description)
	isStarred: \(item.isStarred.description) ---> \(isStarred.description)
""")
			item.isRead = isRead
			item.isStarred = isStarred
			item.record = self
			return item
		} else {
			Logger.sync.info("Merging (remote was older) ❌ \(self.recordID.itemId)")
			return nil
		}
	}
}
