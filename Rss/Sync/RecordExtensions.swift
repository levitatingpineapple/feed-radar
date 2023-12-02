import Foundation
import CloudKit
import os.log

extension CKRecordZone.ID {
	var source: URL { URL(string: zoneName.strippingPrefix("zone:"))! }
}

extension CKRecord.ID {
	var itemId: String { recordName.strippingPrefix(.cloudKitRecordIdPrefix) }
	var source: URL { zoneID.source }
}

extension Feed {
	var zoneID: CKRecordZone.ID {
		CKRecordZone.ID(zoneName: "zone:" + source.absoluteString)
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
	
	func merged(with remoteRecord: CKRecord) -> Item? {
		let isRemoteRead = remoteRecord[Column.isRead.rawValue] as! Bool
		let isRemoteStarred = remoteRecord[Column.isStarred.rawValue] as! Bool
		if record.modificationDate ?? .distantPast < remoteRecord.modificationDate ?? .distantFuture {
			Logger.sync.info("""
Merging (remote was newer) ✅
	itemId: \(itemId)
	isRead: \(isRead.description) ---> \(isRemoteRead.description)
	isStarred: \(isStarred.description) ---> \(isRemoteStarred.description)
""")
			var merged = self
			merged.isRead = isRemoteRead
			merged.isStarred = isRemoteStarred
			merged.record = remoteRecord
			return merged
		} else {
			Logger.sync.info("""
Merging (remote was older) ❌
	itemId: \(itemId)
	isRead: \(isRead.description) -x-> \(isRemoteRead.description)
	isStarred: \(isStarred.description) -x-> \(isRemoteStarred.description)
""")
			return nil
		}
	}
	
	static func stored(with recordID: CKRecord.ID) -> Item? {
		Store.shared.item(source: recordID.zoneID.source, itemId: recordID.itemId)
	}
}
