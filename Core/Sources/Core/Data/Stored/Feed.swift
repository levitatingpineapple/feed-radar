import Foundation
import Combine
import GRDB

/// A storable type that can represent any feed
public struct Feed: Storable {
	/// Source URL of the feed which uniquely identifies it
	public let source: URL
	public let title: String?
	public let icon: URL?
	
	public var id: URL { source }
	
	public var iconData: Data? {
		UserDefaults.standard.data(forKey: .iconKey(source: source))
	}
}

extension Feed {
	public init(source: URL) {
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
	public static func publisherAll(in store: Store) -> AnyPublisher<Array<Feed>, Error> {
		ValueObservation.tracking {
			try Feed
				.order(Column.title.column)
				.fetchAll($0)
		}
		.publisher(in: store.queue, scheduling: .immediate)
		.eraseToAnyPublisher()
	}
	
	public static func publisherSingle(in store: Store, for source: URL) -> AnyPublisher<Feed?, Error> {
		ValueObservation.tracking (
			Feed.filter(Column.source.column == source).fetchOne
		)
		.publisher(in: store.queue, scheduling: .immediate)
		.eraseToAnyPublisher()
	}
}
