import Foundation
import GRDB

extension Item {
	enum Filter: Hashable {
		case unread
		case starred
		case feed(Feed)
		
		var feed: Feed? {
			switch self {
			case let .feed(feed): feed
			default: nil
			}
		}
		
		var navigationTitle: String {
			switch self {
			case .unread: "Unread"
			case .starred: "Starred"
			case .feed(let feed): feed.title ?? feed.source.absoluteString
			}
		}
	}
}
