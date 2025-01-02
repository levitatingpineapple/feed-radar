import Foundation
import Combine
import GRDB
import UniformTypeIdentifiers

/// A storable type that represents ``Item``'s attachment
public struct Attachment: Storable {
	/// Unique identifier created combining attachment's ``url`` with `Item.ID`
	public let id: Int64
	/// The ID of the ``Item`` this attachment belongs to
	public let itemId: Item.ID
	/// URL where attachments contents are located, this uniquely identifies the attachment
	public let url: URL
	/// MIME type of the attachment
	public let mime: String?
	/// Title which is displayed above the preview
	public let title: String?
	/// Attachment's uniform type identifier is used to choosing how to preview it.
	public var type: UTType
	/// A unique local attachment URL in app's `documents/attachments` directory\
	/// A file extension is added for QuickLook compatibility
	public var localUrl: URL
	
	public init(
		itemId: Item.ID,
		url: URL,
		mime: String? = nil,
		title: String? = nil
	) {
		self.id = (url.absoluteString + String(itemId)).stableHash
		self.itemId = itemId
		self.url = url
		self.mime = mime
		self.title = title
		self.type = mime.flatMap { UTType(mimeType: $0) } ?? .item
		self.localUrl = URL
			.attachments(itemId: itemId)
			.appendingPathComponent(
				String(format: "%02x/\(url.lastPathComponent)", id),
				conformingTo: type
			)
	}
}

extension Attachment {
	enum CodingKeys: String, CodingKey {
		case itemId, url, mime, title
		var column: GRDB.Column { GRDB.Column(self.rawValue) }
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self = Attachment(
			itemId: try container.decode(Item.ID.self, forKey: .itemId),
			url: try container.decode(URL.self, forKey: .url),
			mime: try container.decodeIfPresent(String.self, forKey: .mime),
			title: try container.decodeIfPresent(String.self, forKey: .title)
		)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.itemId, forKey: .itemId)
		try container.encode(self.url, forKey: .url)
		try container.encodeIfPresent(self.mime, forKey: .mime)
		try container.encodeIfPresent(self.title, forKey: .title)
	}
}

extension Attachment {
	public static func publisher(
		in store: Store,
		with itemId: Item.ID
	) -> AnyPublisher<Array<Attachment>, Error> {
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


extension Attachment {
	public enum Preview {
		case image
		case video
	}
	
	public var preview: Preview? {
		if type.conforms(to: .image) {
			.image
		} else if type.conforms(to: .audiovisualContent) {
			.video
		} else {
			nil
		}
	}
}
