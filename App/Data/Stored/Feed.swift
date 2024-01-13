import Foundation
import Combine
import GRDB
import GRDBQuery

/// A storable type that can represent any feed
struct Feed: Storable {
	/// Source URL of the feed which uniquely identifies it
	let source: URL
	let title: String?
	let icon: URL?
	
	var id: URL { source }
	
	var iconData: Data? {
		UserDefaults.standard.data(forKey: .iconKey(source: source))
	}
}

extension Feed {
	init(source: URL) {
		self = Feed(source: source, title: nil, icon: nil)
	}
}

extension Feed {
	enum Column: String {
		case source, title, icon
		var column: GRDB.Column { GRDB.Column(self.rawValue) }
	}
}

extension Feed {
	struct RequestAll: Queryable {
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
		let source: URL
		
		func publisher(in store: Store) -> AnyPublisher<Feed?, Error> {
			ValueObservation.tracking (
				Feed.filter(Column.source.column == source).fetchOne
			)
			.publisher(in: store.queue, scheduling: .immediate)
			.eraseToAnyPublisher()
		}
	}
}
