import Foundation
import Combine
import GRDB
import GRDBQuery

/// A storable type that represents an item
struct Item: Storable {
	/// A globally unique id.
	///
	/// Generated by combining `guid` with the source of the ``Feed`` and calculateing a stable hash value
	/// The type required to be `Int64` for `ValueObservation` to work correctly
	let id: Int64
	/// Source of the ``Feed`` this item belongs to
	let source: URL
	/// Title of the item with fallback to guid
	let title: String
	/// Last time article was changed or published
	let time: TimeInterval?
	/// Author of the item - multiple authors are concatinated in a comma separated list
	let author: String?
	/// Plaintext or HTML content
	let content: String?
	/// URL That points to ``Item``'s content. Used for extracting articles
	let url: URL?
	/// Can be mofified by the user and is synced
	var isRead: Bool = false
	/// Can be mofified by the user and is synced
	var isStarred: Bool = false
	/// Sync contains archived `CKRecord`, which needs to be persisted inorder to compare upload times
	var sync: Data?
	/// The content extracted from ``Item``'s url
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
			ValueObservation.tracking(filter.items.fetchCount)
				.publisher(in: store.queue, scheduling: .immediate)
				.removeDuplicates()
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

	struct RequestRedacted: Queryable {
		static let defaultValue: Item? = nil
		let id: Item.ID

		private static let columns: Array<Column> = [
			.id, .source, .title, .time, .author, .url, .isRead, .isStarred
		]

		func publisher(in store: Store) -> AnyPublisher<Item?, Error> {
			ValueObservation.tracking { database in
				try Row
					.fetchOne(
						database,
						Item.select(Self.columns.map { $0.column }).filter(key: id)
					)
					.map {
						Item(
							id: $0[Column.id.rawValue],
							source: $0[Column.source.rawValue],
							title: $0[Column.title.rawValue],
							time: $0[Column.time.rawValue],
							author: $0[Column.author.rawValue],
							content: nil, // Redacted
							url: $0[Column.url.rawValue],
							isRead: $0[Column.isRead.rawValue],
							isStarred: $0[Column.isStarred.rawValue],
							sync: nil, // Redacted
							extracted: nil // Redacted
						)
					}
			}
			.publisher(in: store.queue, scheduling: .immediate)
			.eraseToAnyPublisher()
		}
	}
}
