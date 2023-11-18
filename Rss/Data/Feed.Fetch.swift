import Foundation
import FeedKit

extension Feed {
	convenience init(url: URL) async throws {
		switch FeedParser(URL: url).parse() {
		case let .success(feed):
			let items = Array<Item>(feed: feed)
			switch feed {
			case let .atom(atom):
				self.init(
					url: url,
					title: atom.title,
					id: url.absoluteString,
					icon: Self.icon(imageUrl: atom.icon?.url, faviconUrl: url),
					items: items
				)
			case let .rss(rss):
				self.init(
					url: url,
					title: rss.title,
					id: url.absoluteString,
					icon: Self.icon(
						imageUrl: rss.image?.url?.url, 
						faviconUrl: rss.link?.url ?? url
					),
					items: items
				)
			case let .json(json):
				self.init(
					url: url,
					title: json.title,
					id: url.absoluteString,
					icon: Self.icon(imageUrl: json.icon?.url, faviconUrl: url),
					items: items
				)
			}
		case let .failure(parserError):
			throw parserError
		}
	}
	
	private static func icon(imageUrl: URL?, faviconUrl: URL) -> Data? {
		(imageUrl ?? faviconUrl.favicon)
			.flatMap { try? Data(contentsOf: $0) }
	}
}
