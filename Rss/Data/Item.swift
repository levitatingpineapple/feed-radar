import Foundation
import Combine
import GRDB
import GRDBQuery

struct Item: Hashable, Identifiable, Codable, FetchableRecord, PersistableRecord {
	enum Column: String {
		case itemId, feedUrl, time, title, author, content, url
	}
	
	let itemId: String
	let feedUrl: URL
	let time: TimeInterval?
	let title: String?
	let author: String?
	let content: String?
	let url: URL?
	
	var id: Int { .hashValues(feedUrl, itemId) }
	
	static func createTable(database: Database) throws {
		try database.create(table: "item", options: .ifNotExists) {
			$0.column(Column.feedUrl.rawValue, .text).notNull()
			$0.column(Column.itemId.rawValue, .text).notNull()
			$0.column(Column.time.rawValue, .double)
			$0.column(Column.title.rawValue, .text)
			$0.column(Column.author.rawValue, .text)
			$0.column(Column.content.rawValue, .text)
			$0.column(Column.url.rawValue, .text)
			$0.primaryKey([Column.feedUrl.rawValue, Column.itemId.rawValue], onConflict: .replace)
			$0.foreignKey([Column.feedUrl.rawValue], references: "feed", onDelete: .cascade)
		}
	}
}

extension Item {
	struct Request: Queryable {
		static var defaultValue = Array<Item>()
		
		var filter: Filter
		
		func publisher(in store: Store) -> AnyPublisher<Array<Item>, Error> {
			ValueObservation.tracking {
				switch filter {
				case .all:
					try Item
						.order(GRDB.Column(Column.time.rawValue).desc)
						.fetchAll($0)
				case let .feed(feed):
					try Item
						.filter(GRDB.Column(Column.feedUrl.rawValue) == feed.url.absoluteString)
						.order(GRDB.Column(Column.time.rawValue).desc)
						.fetchAll($0)
				}
			}
			.publisher(in: store.queue, scheduling: .immediate)
			.eraseToAnyPublisher()
		}
	}
}
