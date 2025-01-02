import Foundation
import GRDB

/// Filters ``Item`` list. Used by `Item.RequestIDs` and `Item.RequestCount`
public struct Filter: Hashable, Codable, Sendable {
	public var feed: Feed? = nil
	public var isRead: Bool? = nil
	public var isStarred: Bool? = nil
	
	public init(
		feed: Feed? = nil,
		isRead: Bool? = nil,
		isStarred: Bool? = nil
	) {
		self.feed = feed
		self.isRead = isRead
		self.isStarred = isStarred
	}
	
	public var title: String {
		if let feed {
			feed.title ?? feed.source.absoluteString
		} else if isRead != nil || isStarred != nil {
			[
				isRead.flatMap { $0 ? "Read" : "Unread" },
				isStarred.flatMap { $0 ? "Starred" : "Unstarred" }
			]
				.compactMap { $0 }
				.joined(separator: " & ")
		} else {
			"Inbox"
		}
	}
	
	private var filters: Array<SQLExpression> {
		[
			feed.flatMap { Item.Column.source.column == $0.source },
			isRead.flatMap { Item.Column.isRead.column == $0 },
			isStarred.flatMap { Item.Column.isStarred.column == $0 }
		].compactMap { $0 }
	}
	
	public var items: QueryInterfaceRequest<Item> {
		filters.reduce(into: Item.all()) {
			$0 = $0.filter($1)
		}
	}
	
	/// A filter with additional unread filter applied
	public var unread: Filter {
		var filter = self
		filter.isRead = false
		return filter
	}
}

extension Filter: RawRepresentable {
	public init?(rawValue: Data) {
		self = try! JSONDecoder().decode(Filter.self, from: rawValue)
	}
	
	public var rawValue: Data {
		try! JSONEncoder().encode(self)
	}
}
