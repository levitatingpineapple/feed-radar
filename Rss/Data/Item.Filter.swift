import Foundation
import GRDB

extension Item {
	enum Filter: Hashable {
		case unread
		case starred
		case feed(Feed)
		
		var source: URL? {
			switch self {
			case let .feed(feed): feed.source
			default: nil
			}
		}
	}
}
