import Foundation
import Combine
import GRDB
import GRDBQuery

struct Item: Storable {
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
}

extension Item {
	enum Column: String {
		case id, source, title, time, author, content, url,
			 isRead, isStarred, sync, extracted
		var column: GRDB.Column { GRDB.Column(self.rawValue) }
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
				.throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
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
