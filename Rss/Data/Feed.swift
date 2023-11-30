import Foundation
import Combine
import GRDB
import GRDBQuery


struct Feed: Hashable, Identifiable, Codable, FetchableRecord, PersistableRecord {
	enum Column: String {
		case source, title, icon
		var column: GRDB.Column { GRDB.Column(self.rawValue) }
	}
	
	let source: URL
	let title: String?
	let icon: URL?
	
	var id: Int { source.hashValue }
	
	static func createTable(database: Database) throws {
		try database.create(table: "feed", options: .ifNotExists) {
			$0.column(Column.source.rawValue, .text).notNull()
			$0.column(Column.title.rawValue, .text)
			$0.column(Column.icon.rawValue, .text)
			$0.primaryKey([Column.source.rawValue], onConflict: .replace)
		}
	}
}

extension Feed {
	init(source: URL) {
		self = Feed(source: source, title: nil, icon: nil)
	}
}

extension Feed {
	struct Request: Queryable {
		static var defaultValue = Array<Feed>()
		
		func publisher(in store: Store) -> AnyPublisher<Array<Feed>, Error> {
			ValueObservation.tracking {
				try Feed
					.order(Column.title.column)
					.fetchAll($0)
			}
			.publisher(in: store.queue, scheduling: .immediate)
			.eraseToAnyPublisher()
		}
	}
	
	struct RequestSingle: Queryable {
		static var defaultValue: Feed? = nil
		let url: URL
		
		func publisher(in store: Store) -> AnyPublisher<Feed?, Error> {
			ValueObservation.tracking {
				try Feed
					.filter(Column.source.column == url.absoluteString)
					.fetchOne($0)
			}
			.publisher(in: store.queue, scheduling: .immediate)
			.eraseToAnyPublisher()
		}
	}
}
