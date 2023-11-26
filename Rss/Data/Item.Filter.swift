import Foundation
import GRDB

extension Item {
	enum Filter: Hashable {
		case unread
		case starred
		case feed(Feed)
		
		var feedUrl: URL? {
			switch self {
			case let .feed(feed): feed.url
			default: nil
			}
		}
	}
	
	
}
