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
				?? rss.iTunes?.iTunesImage?.attributes?.href?.url
				?? (rss.link?.url ?? source).favicon
			),
			items: (rss.items ?? Array<RSSFeedItem>()).compactMap { rssItem in
				rssItem.guid?.value.flatMap { guid in
					Item(
						id: (source.absoluteString + guid).stableHash,
						source: source,
						title: rssItem.title ?? guid,
						time: rssItem.pubDate?.timeIntervalSince1970,
						author: rssItem.author ?? rssItem.dublinCore?.dcCreator,
						content: rssItem.content?.contentEncoded ?? rssItem.description,
						url: rssItem.link?.url
					)
				}
			},
			attachments: rss.items.flatMap {
				$0.compactMap { rssItem in
					{
						if let guid = rssItem.guid?.value,
						   let url = rssItem.enclosure?.attributes?.url?.url,
						   let type = rssItem.enclosure?.attributes?.type {
							[Attachment(
								itemId: (source.absoluteString + guid).stableHash,
								url: url,
								mime: type,
								title: nil
							)]
						} else { Array<Attachment>() }
					}() + {
						if let guid = rssItem.guid?.value,
						   let mediaContents = rssItem.media?.mediaContents {
							mediaContents.compactMap { mediaContent in
								if let url = mediaContent.attributes?.url?.url,
								   let type = mediaContent.attributes?.type {
									Attachment(
										itemId: (source.absoluteString + guid).stableHash,
										url: url,
										mime: type,
										title: mediaContent.mediaDescription?.value
									)
								} else { nil }
							}
						} else { Array<Attachment>() }
					}()
				}.flatMap { $0 }
			} ?? Array<Attachment>()
		)
	}
}
