import Foundation
import Combine
import GRDB
import GRDBQuery


struct Feed: Hashable, Identifiable, Codable, FetchableRecord, PersistableRecord {
	enum Column: String {
		case source, title, icon
	}
	
	let source: URL
	let title: String?
	let icon: Data?
	
	var id: Int { source.hashValue }
	
	static func createTable(database: Database) throws {
		try database.create(table: "feed", options: .ifNotExists) {
			$0.column(Column.source.rawValue, .text).notNull()
			$0.column(Column.title.rawValue, .text)
			$0.column(Column.icon.rawValue, .blob)
			$0.primaryKey([Column.source.rawValue], onConflict: .ignore)
		}
	}
}

extension Feed {
	struct Request: Queryable {
		static var defaultValue = Array<Feed>()
		
		func publisher(in store: Store) -> AnyPublisher<Array<Feed>, Error> {
			ValueObservation.tracking {
				try Feed
					.order(GRDB.Column(Column.title.rawValue))
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
					.filter(GRDB.Column(Column.source.rawValue) == url.absoluteString)
					.fetchOne($0)
			}
				.publisher(in: store.queue, scheduling: .immediate)
				.eraseToAnyPublisher()
		}
	}
}



extension Feed {
	enum Display {
		case content(scale: Double)
		case web(reader: Bool, inverted: Bool)
	}
}
