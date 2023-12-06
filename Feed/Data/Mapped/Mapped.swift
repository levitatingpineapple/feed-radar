import Foundation
import FeedKit
import UniformTypeIdentifiers

struct Mapped {
	let feed: Feed
	let items: Array<Item>
	let attachments: Array<Attachment>
}
	
extension Mapped {
	init(feed: FeedKit.Feed, at source: URL) {
		self = switch feed {
		case let .atom(atom): Mapped(atom, at: source)
		case let .rss(rss): Mapped(rss, at: source)
		case let .json(json): Mapped(json, at: source)
		}
	}
}
