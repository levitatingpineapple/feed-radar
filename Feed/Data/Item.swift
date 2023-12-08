import Foundation
import Combine
import GRDB
import GRDBQuery

struct Item: Hashable, Identifiable, Codable, FetchableRecord, PersistableRecord {
	enum Column: String {
		case id, source, title, time, author, content, url,
			 isRead, isStarred, sync, extracted
		var column: GRDB.Column { GRDB.Column(self.rawValue) }
	}
	
	let id: Int64
	let source: URL
	let title: String
	let time: TimeInterval?
	let author: String?
	let content: String?
	let url: URL?
	
	var isRead: Bool = false
	var isStarred: Bool = false
	var sync: Data?
	var extracted: String?
	
	static func createTable(database: Database) throws {
		try database.create(table: "item", options: .ifNotExists) {
			$0.column(Column.id.rawValue, .integer).primaryKey(onConflict: .replace)
			$0.column(Column.source.rawValue, .text).notNull()
			$0.column(Column.title.rawValue, .text).notNull()
			$0.column(Column.time.rawValue, .double)
			$0.column(Column.author.rawValue, .text)
			$0.column(Column.content.rawValue, .text)
			$0.column(Column.url.rawValue, .text)
			$0.column(Column.isRead.rawValue, .boolean)
			$0.column(Column.isStarred.rawValue, .boolean)
			$0.column(Column.sync.rawValue, .blob)
			$0.column(Column.extracted.rawValue, .text)
			$0.foreignKey([Column.source.rawValue], references: "feed", onDelete: .cascade)
		}
	}
}

extension Item {
	struct RequestIDs: Queryable {
		static var defaultValue = Array<Int64>()
		
		let filter: Filter
		
		func publisher(in store: Store) -> AnyPublisher<Array<Int64>, Error> {
			ValueObservation.tracking {
				try Row
					.fetchAll($0, filter.items.order(Column.time.column.desc))
					.map { $0[Column.id.rawValue] }
			}
			.publisher(in: store.queue, scheduling: .immediate)
			.eraseToAnyPublisher()
		}
	}

	struct RequestCount: Queryable {
		static var defaultValue: Int = .zero
		
		let filter: Filter
		
		func publisher(in store: Store) -> AnyPublisher<Int, Error> {
			ValueObservation.tracking { try filter.items.fetchCount($0) }
				.publisher(in: store.queue, scheduling: .immediate)
				.eraseToAnyPublisher()
		}
	}

	struct RequestSingle: Queryable {
		static let defaultValue: Item? = nil
		let id: Item.ID
		
		func publisher(in store: Store) -> AnyPublisher<Item?, Error> {
			ValueObservation.tracking(Item.filter(key: id).fetchOne)
				.publisher(in: store.queue, scheduling: .immediate)
				.eraseToAnyPublisher()
		}
	}
}
