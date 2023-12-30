import Foundation
import FeedKit
import UniformTypeIdentifiers

extension Mapped {
	init(_ rss: RSSFeed, at source: URL) {
		self = Mapped(
			feed: Feed(
				source: source,
				title: rss.title,
				icon: rss.image?.url?.url
				?? (rss.link?.url ?? source).favicon
			),
			items: (rss.items ?? Array<RSSFeedItem>()).compactMap { rssItem in
				rssItem.guid?.value.flatMap { itemId in
					Item(
						id: (source.absoluteString + itemId).stableHash,
						source: source,
						title: rssItem.title ?? itemId,
						time: rssItem.pubDate?.timeIntervalSince1970,
						author: rssItem.author ?? rss.items?.first?.dublinCore?.dcCreator,
						content: rssItem.content?.contentEncoded ?? rssItem.description,
						url: rssItem.link?.url
					)
				}
			},
			attachments: rss.items.flatMap {
				$0.compactMap { rssItem in
					if let itemId = rssItem.guid?.value,
					   let url = rssItem.enclosure?.attributes?.url?.url,
					   let type = rssItem.enclosure?.attributes?.type?.type {
						Attachment(
							id: (source.absoluteString + itemId).stableHash,
							url: url,
							type: type,
							title: nil
						)
					} else { nil }
				}
			} ?? Array<Attachment>()
		)
	}
}
