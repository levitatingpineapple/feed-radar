import Foundation
import Combine
import GRDB
import GRDBQuery


struct Feed: Hashable, Identifiable, Codable, FetchableRecord, PersistableRecord {
	enum Column: String {
		case url, title, icon
	}
	
	let url: URL
	let title: String?
	let icon: Data?
	
	var id: Int { url.hashValue }
	
	static func createTable(database: Database) throws {
		try database.create(table: "feed", options: .ifNotExists) {
			$0.column(Column.url.rawValue, .text).notNull()
			$0.column(Column.title.rawValue, .text)
			$0.column(Column.icon.rawValue, .blob)
			$0.primaryKey([Column.url.rawValue], onConflict: .ignore)
		}
	}
}

extension Feed {
	struct Request: Queryable {
		static var defaultValue = Array<Feed>()
		
		func publisher(in store: Store) -> AnyPublisher<Array<Feed>, Error> {
			ValueObservation.tracking { try Feed.fetchAll($0) }
				.publisher(in: store.queue, scheduling: .immediate)
				.eraseToAnyPublisher()
		}
	}
}
