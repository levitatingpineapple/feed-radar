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
	/// Title which is displayed above the preview
	let title: String?
	/// Attachment's uniform type identifier is used to choosing how to preview it.
	var type: UTType
	/// A unique local attachment URL in app's `documents/attachments` directory\
	/// File extension is added for QuickLook compatibility
	var localUrl: URL
	/// Unique identifier
	var id: Int
	
	init(
		itemId: Item.ID,
		url: URL,
		mime: String? = nil,
		title: String? = nil
	) {
		self.itemId = itemId
		self.url = url
		self.mime = mime
		self.title = title
		self.id = url.hashValue
		self.type = mime.flatMap { UTType(mimeType: $0) } ?? .item
		self.localUrl = URL.documents.appendingPathComponent(
			"attachments/" +
			String(format: "%02x/", url.absoluteString.stableHash) +
			url.lastPathComponent,
			conformingTo: type
		)
	}
}

extension Attachment {
	enum CodingKeys: String, CodingKey {
		case itemId, url, mime, title
		var column: GRDB.Column { GRDB.Column(self.rawValue) }
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self = Attachment(
			itemId: try container.decode(Item.ID.self, forKey: .itemId),
			url: try container.decode(URL.self, forKey: .url),
			mime: try container.decodeIfPresent(String.self, forKey: .mime),
			title: try container.decodeIfPresent(String.self, forKey: .title)
		)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.itemId, forKey: .itemId)
		try container.encode(self.url, forKey: .url)
		try container.encodeIfPresent(self.mime, forKey: .mime)
		try container.encodeIfPresent(self.title, forKey: .title)
	}
}

extension Attachment {
	/// A request to fetch all attachments of an item
	struct Request: Queryable {
		static var defaultValue = Array<Attachment>()
		
		let itemId: Item.ID
		
		func publisher(in store: Store) -> AnyPublisher<Array<Attachment>, Error> {
			ValueObservation
				.tracking(
					Attachment
						.filter(CodingKeys.itemId.column == itemId)
						.fetchAll
				)
				.publisher(in: store.queue, scheduling: .immediate)
				.eraseToAnyPublisher()
		}
	}
}
