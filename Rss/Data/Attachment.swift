import Foundation
import Combine
import GRDB
import GRDBQuery
import UniformTypeIdentifiers

struct Attachment: Hashable, Identifiable {
	enum Column: String {
		case feedUrl, itemId, url, type, title
	}
	
	let feedUrl: URL
	let itemId: String
	let url: URL
	let type: UTType
	let title: String?
	
	var id: Int { .hashValues(feedUrl, itemId, url) }
	
	static func createTable(database: Database) throws {
		try database.create(table: "attachment", options: .ifNotExists) {
			$0.column(Column.feedUrl.rawValue).notNull()
			$0.column(Column.itemId.rawValue).notNull()
			$0.column(Column.url.rawValue).notNull()
			$0.column(Column.type.rawValue)
			$0.column(Column.title.rawValue)
			$0.primaryKey([Column.feedUrl.rawValue, Column.itemId.rawValue, Column.url.rawValue], onConflict: .replace)
			$0.foreignKey([Column.feedUrl.rawValue, Column.itemId.rawValue], references: "item")
		}
	}
}

extension Attachment: FetchableRecord {
	init(row: GRDB.Row) throws {
		feedUrl = row[Column.feedUrl.rawValue]
		itemId = row[Column.itemId.rawValue]
		url = row[Column.url.rawValue]
		type = UTType(row[Column.type.rawValue])!
		title = row[Column.url.rawValue]
	}
}

extension Attachment: PersistableRecord {
	func encode(to container: inout GRDB.PersistenceContainer) throws {
		container[Column.feedUrl.rawValue] = feedUrl
		container[Column.itemId.rawValue] = itemId
		container[Column.url.rawValue] = url
		container[Column.type.rawValue] = type.identifier
		container[Column.title.rawValue] = title
	}
}

extension Attachment {
	struct Request: Queryable {
		static var defaultValue = Array<Attachment>()
		
		var feedUrl: URL
		var itemId: String
		
		func publisher(in store: Store) -> AnyPublisher<Array<Attachment>, Error> {
			ValueObservation
				.tracking {
					try Attachment
						.filter(GRDB.Column(Column.feedUrl.rawValue) == feedUrl.absoluteString)
						.filter(GRDB.Column(Column.itemId.rawValue) == itemId)
						.fetchAll($0)
				}
				.publisher(in: store.queue, scheduling: .immediate)
				.eraseToAnyPublisher()
		}
	}
}
