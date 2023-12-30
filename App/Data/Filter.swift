import Foundation
import GRDB


struct Filter: Hashable, Codable {
	var feed: Feed? = nil
	var isRead: Bool? = nil
	var isStarred: Bool? = nil
	
	var title: String {
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
	
	var items: QueryInterfaceRequest<Item> {
		filters.reduce(
			into: Item.select([Item.Column.id.column])
		) { $0 = $0.filter($1) }
	}
	
	func unread() -> Filter {
		var filter = self
		filter.isRead = false
		return filter
	}
}

extension Filter: RawRepresentable {
	init?(rawValue: Data) {
		self = try! JSONDecoder().decode(Filter.self, from: rawValue)
	}
	
	var rawValue: Data {
		try! JSONEncoder().encode(self)
	}
}
