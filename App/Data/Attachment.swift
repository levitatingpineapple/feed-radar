import Foundation
import Combine
import GRDB
import GRDBQuery
import CryptoKit
import UniformTypeIdentifiers

struct Attachment: Hashable {
	enum Column: String {
		case id, url, type, title
		var column: GRDB.Column { GRDB.Column(self.rawValue) }
	}
	
	let id: Item.ID
	let url: URL
	let type: UTType
	let title: String?
	
	
	var localUrl: URL {
		URL.documents.appendingPathComponent(
			"attachments/" +
			SHA256.hash(data: url.dataRepresentation)
				.compactMap { String(format: "%02x", $0) }
				.joined() + "/" + url.lastPathComponent,
			conformingTo: type
		)
	}
	
	static func createTable(database: Database) throws {
		try database.create(table: "attachment", options: .ifNotExists) {
			$0.column(Column.id.rawValue).notNull()
			$0.column(Column.url.rawValue).notNull()
			$0.column(Column.type.rawValue)
			$0.column(Column.title.rawValue)
			$0.primaryKey([Column.url.rawValue], onConflict: .replace)
			$0.foreignKey([Column.id.rawValue], references: "item", onDelete: .cascade)
		}
	}
}

extension Attachment: FetchableRecord {
	init(row: GRDB.Row) throws {
		id = row[Column.id.rawValue]
		url = row[Column.url.rawValue]
		type = UTType(row[Column.type.rawValue])!
		title = row[Column.title.rawValue]
	}
}

extension Attachment: PersistableRecord {
	func encode(to container: inout GRDB.PersistenceContainer) throws {
		container[Column.id.rawValue] = id
		container[Column.url.rawValue] = url
		container[Column.type.rawValue] = type.identifier
		container[Column.title.rawValue] = title
	}
}

extension Attachment {
	struct Request: Queryable {
		static var defaultValue = Array<Attachment>()
		
		let id: Item.ID
		
		func publisher(in store: Store) -> AnyPublisher<Array<Attachment>, Error> {
			ValueObservation
				.tracking {
					try Attachment
						.filter(Column.id.column == id)
						.fetchAll($0)
				}
				.publisher(in: store.queue, scheduling: .immediate)
				.eraseToAnyPublisher()
		}
	}
}
