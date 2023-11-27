import Foundation
import Combine
import GRDB
import GRDBQuery

struct Item: Hashable, Identifiable, Codable, FetchableRecord, PersistableRecord {
	enum Column: String {
		case itemId, source, time, title, author, content, url, isRead, isStarred, sync
		var column: GRDB.Column { GRDB.Column(self.rawValue) }
	}
	
	let itemId: String
	let source: URL
	let time: TimeInterval?
	let title: String?
	let author: String?
	let content: String?
	let url: URL?
	
	
	// Sync
	var isRead: Bool = false
	var isStarred: Bool = false
	var sync: Data? = nil
	
	var id: Int { .hashValues(source, itemId) }
	
	static func createTable(database: Database) throws {
		try database.create(table: "item", options: .ifNotExists) {
			$0.column(Column.source.rawValue, .text).notNull()
			$0.column(Column.itemId.rawValue, .text).notNull()
			$0.column(Column.time.rawValue, .double)
			$0.column(Column.title.rawValue, .text)
			$0.column(Column.author.rawValue, .text)
			$0.column(Column.content.rawValue, .text)
			$0.column(Column.url.rawValue, .text)
			$0.column(Column.isRead.rawValue, .boolean)
			$0.column(Column.isStarred.rawValue, .boolean)
			$0.column(Column.sync.rawValue, .blob)
			$0.primaryKey([Column.source.rawValue, Column.itemId.rawValue], onConflict: .replace)
			$0.foreignKey([Column.source.rawValue], references: "feed", onDelete: .cascade)
		}
	}
}

extension Item {
	struct Request: Queryable {
		static var defaultValue = Array<Item>()
		
		let filter: Filter
		
		var predicate: some SQLSpecificExpressible {
			switch filter {
			case .unread:
				Column.isRead.column == false
			case .starred:
				Column.isStarred.column == true
			case let .feed(feed):
				Column.source.column == feed.source.absoluteString
			}
		}
		
		func publisher(in store: Store) -> AnyPublisher<Array<Item>, Error> {
			ValueObservation.tracking {
				try Item
					.filter(predicate)
					.order(Column.time.column.desc)
					.fetchAll($0)
			}
			.publisher(in: store.queue, scheduling: .immediate)
			.eraseToAnyPublisher()
		}
	}
}

extension Item {
	struct RequestCount: Queryable {
		static var defaultValue: Int = .zero
		
		let filter: Filter
		
		var predicate: some SQLSpecificExpressible {
			switch filter {
			case .unread:
				Column.isRead.column == false
			case .starred:
				Column.isStarred.column == true
			case let .feed(feed):
				Column.isRead.column == false &&
				Column.source.column == feed.source.absoluteString
			}
		}
		
		func publisher(in store: Store) -> AnyPublisher<Int, Error> {
			ValueObservation.tracking { try Item.filter(predicate).fetchCount($0) }
			.publisher(in: store.queue, scheduling: .immediate)
			.eraseToAnyPublisher()
		}
	}
}
