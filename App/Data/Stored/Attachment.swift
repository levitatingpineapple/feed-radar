import Foundation
import Combine
import GRDB
import GRDBQuery
import CryptoKit
import UniformTypeIdentifiers

/// A storable type that represents ``Item``'s attachment
struct Attachment: Storable {
	/// The ID of the ``Item`` this attachment belongs to
	let itemId: Item.ID
	/// URL where attachments contents are locaed, this uniquely identifies the attachment
	let url: URL
	/// MIME type of the attachment
	let mime: String?
	/// Title that is displayed above the preview
	let title: String?
	
	/// Attachment's uniform type identifier is used to choosing how to preview it.
	var type: UTType {
		mime.flatMap { UTType(mimeType: $0) } ?? .item
	}
	/// A unique local attachment URL in app's `documents/attachments` directory\
	/// File extension is added for QuickLook compatibility
	var localUrl: URL {
		URL.documents.appendingPathComponent(
			"attachments/" +
			SHA256.hash(data: url.dataRepresentation)
				.compactMap { String(format: "%02x", $0) }
				.joined() + "/" + url.lastPathComponent,
			conformingTo: type
		)
	}
	
	var id: Int { url.hashValue }
}

extension Attachment {
	enum Column: String {
		case itemId, url, mime, title
		var column: GRDB.Column { GRDB.Column(self.rawValue) }
	}
}

extension Attachment {
	/// A request to fetch all attachments of an item
	struct Request: Queryable {
		static var defaultValue = Array<Attachment>()
		
		let itemId: Item.ID
		
		func publisher(in store: Store) -> AnyPublisher<Array<Attachment>, Error> {
			ValueObservation
				.tracking {
					try Attachment
						.filter(Column.itemId.column == itemId)
						.fetchAll($0)
				}
				.publisher(in: store.queue, scheduling: .immediate)
				.eraseToAnyPublisher()
		}
	}
}
