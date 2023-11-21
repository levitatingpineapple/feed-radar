import Foundation
import FeedKit
import UniformTypeIdentifiers

struct Mapped {
	let feed: Feed
	let items: Array<Item>
	let attachments: Array<Attachment>
}
	
extension Mapped {
	init(feed: FeedKit.Feed, at feedUrl: URL) {
		self = switch feed {
		case let .atom(atom): Mapped(atom, at: feedUrl)
		case let .rss(rss): Mapped(rss, at: feedUrl)
		case let .json(json): Mapped(json, at: feedUrl)
		}
	}

	static func icon(imageUrl: URL?, faviconUrl: URL) -> Data? {
		(imageUrl ?? faviconUrl.favicon)
			.flatMap { try? Data(contentsOf: $0) }
	}
}
