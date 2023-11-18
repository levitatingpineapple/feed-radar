import Foundation
import FeedKit

extension Array where Element == Item {
	init(url: URL) async throws {
		switch FeedParser(URL: url).parse() {
		case let .success(feed):
			self.init(feed: feed)
		case let .failure(parserError):
			throw parserError
		}
	}
	
	init(feed: FeedKit.Feed) {
		switch feed {
		case let .atom(atom):
			self.init(
				(atom.entries ?? Array<AtomFeedEntry>())
					.compactMap { entry in
						entry.id.flatMap {
							Item(
								id: $0,
								date: entry.published,
								title: entry.title,
								author: entry.authors?.compactMap { $0.name }.joined(separator: ", "),
								content: entry.content?.value,
								url: entry.links?.first?.attributes?.href?.url
							)
						}
					}
			)
		case let .rss(rss):
			self.init(
				(rss.items ?? []).compactMap { rssItem in
					rssItem.guid?.value.flatMap {
						Item(
							id: $0,
							date: rssItem.pubDate,
							title: rssItem.title,
							author: rssItem.author ?? rss.items?.first?.dublinCore?.dcCreator,
							content: rssItem.content?.contentEncoded ?? rssItem.description,
							url: rssItem.link?.url
						)
					}
				}
			)
		case let .json(json):
			self.init(
				(json.items ?? []).compactMap { jsonItem in
					jsonItem.id.flatMap {
						Item(
							id: $0,
							date: jsonItem.datePublished,
							title: jsonItem.title,
							author: jsonItem.author?.name,
							content: jsonItem.contentHtml ?? jsonItem.contentText,
							url: jsonItem.url?.url
						)
					}
				}
			)
		}
	}
}
