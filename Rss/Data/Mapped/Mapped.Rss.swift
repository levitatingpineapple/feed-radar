import Foundation
import FeedKit
import UniformTypeIdentifiers

extension Mapped {
	init(_ rss: RSSFeed, at feedUrl: URL) {
		self = Mapped(
			feed: Feed(
				url: feedUrl,
				title: rss.title,
				icon: Mapped.icon(
					imageUrl: rss.image?.url?.url,
					faviconUrl: rss.link?.url ?? feedUrl
				)
			),
			items: (rss.items ?? Array<RSSFeedItem>()).compactMap { rssItem in
				rssItem.guid?.value.flatMap {
					Item(
						itemId: $0,
						feedUrl: feedUrl,
						time: rssItem.pubDate?.timeIntervalSince1970,
						title: rssItem.title,
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
							feedUrl: feedUrl,
							itemId: itemId,
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
