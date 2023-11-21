import Foundation
import FeedKit
import UniformTypeIdentifiers

extension Mapped {
	init(_ json: JSONFeed, at feedUrl: URL) {
		self = Mapped(
			feed: Feed(
				url: feedUrl,
				title: json.title,
				icon: Mapped.icon(
					imageUrl: json.icon?.url,
					faviconUrl: json.feedUrl?.url ?? json.homePageURL?.url ?? feedUrl
				)
			),
			items: json.items.flatMap {
				$0.compactMap { jsonItem in
					if let itemId = jsonItem.id {
						Item(
							itemId: itemId,
							feedUrl: feedUrl,
							time: jsonItem.datePublished?.timeIntervalSince1970,
							title: jsonItem.title,
							author: jsonItem.author?.name,
							content: jsonItem.contentHtml ?? jsonItem.contentText,
							url: jsonItem.url?.url
						)
					} else { nil }
				}
			} ?? Array<Item>(),
			attachments: json.items.flatMap {
				$0.compactMap { jsonItem in
					if let itemId = jsonItem.id,
					   let attachments = jsonItem.attachments {
						attachments.compactMap { attachment in
							if let url = attachment.url?.url,
							   let type = attachment.mimeType?.type {
								Attachment(
									feedUrl: feedUrl,
									itemId: itemId,
									url: url,
									type: type,
									title: attachment.title
								)
							} else { nil }
						}
					} else { nil }
				} .flatMap { $0 }
			} ?? Array<Attachment>()
		)
	}
}
