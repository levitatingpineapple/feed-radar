import SwiftUI
import SwiftData

enum Filter: Hashable {
	case all
	case feed(Feed)
	
	var query: Query<Array<Item>.Element, Array<Item>> {
		switch self {
		case .all:
			return Query(
				sort: \Item.date,
				order: .reverse
			)
		case let .feed(feed):
			let id = feed.id
			return Query(
				filter: #Predicate<Item> { item in item.feed?.id == id },
				sort: \.date,
				order: .reverse
			)
		}
	}
	
	var title: String {
		switch self {
		case .all: "All"
		case let .feed(feed): feed.title ?? feed.url.absoluteString
		}
	}
}
