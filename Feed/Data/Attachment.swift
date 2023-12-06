import Foundation
import Combine
import GRDB
import GRDBQuery
import CryptoKit
import UniformTypeIdentifiers

struct Attachment: Hashable, Identifiable {
	enum Column: String {
		case source, itemId, url, type, title
		var column: GRDB.Column { GRDB.Column(self.rawValue) }
	}
	
	let source: URL
	let itemId: String
	let url: URL
	let type: UTType
	let title: String?
	
	var id: Int { .hashValues(source, itemId, url) }
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
			$0.column(Column.source.rawValue).notNull()
			$0.column(Column.itemId.rawValue).notNull()
			$0.column(Column.url.rawValue).notNull()
			$0.column(Column.type.rawValue)
			$0.column(Column.title.rawValue)
			$0.primaryKey([Column.source.rawValue, Column.itemId.rawValue, Column.url.rawValue], onConflict: .replace)
			$0.foreignKey([Column.source.rawValue, Column.itemId.rawValue], references: "item", onDelete: .cascade)
		}
	}
}

extension Attachment: FetchableRecord {
	init(row: GRDB.Row) throws {
		source = row[Column.source.rawValue]
		itemId = row[Column.itemId.rawValue]
		url = row[Column.url.rawValue]
		type = UTType(row[Column.type.rawValue])!
		title = row[Column.title.rawValue]
	}
}

extension Attachment: PersistableRecord {
	func encode(to container: inout GRDB.PersistenceContainer) throws {
		container[Column.source.rawValue] = source
		container[Column.itemId.rawValue] = itemId
		container[Column.url.rawValue] = url
		container[Column.type.rawValue] = type.identifier
		container[Column.title.rawValue] = title
	}
}

extension Attachment {
	struct Request: Queryable {
		static var defaultValue = Array<Attachment>()
		
		var source: URL
		var itemId: String
		
		func publisher(in store: Store) -> AnyPublisher<Array<Attachment>, Error> {
			ValueObservation
				.tracking {
					try Attachment
						.filter(Column.source.column == source)
						.filter(Column.itemId.column == itemId)
						.fetchAll($0)
				}
				.publisher(in: store.queue, scheduling: .immediate)
				.eraseToAnyPublisher()
		}
	}
}
