import Foundation
import FeedKit
import UniformTypeIdentifiers

extension Mapped {
	init(_ atom: AtomFeed, at feedUrl: URL) {
		self = Mapped(
			feed: Feed(
				url: feedUrl,
				title: atom.title,
				icon: Mapped.icon(
					imageUrl: atom.icon?.url,
					faviconUrl: atom.links?.first?.attributes?.href?.url ?? feedUrl
				)
			),
			items: atom.entries.flatMap {
				$0.compactMap { atomEntrie in
					if let itemId = atomEntrie.id {
						Item(
							itemId: itemId,
							feedUrl: feedUrl,
							time: atomEntrie.published?.timeIntervalSince1970,
							title: atomEntrie.title,
							author: atomEntrie.authors?
								.compactMap { $0.name }
								.joined(separator: ", "),
							content: atomEntrie.content?.value,
							url: atomEntrie.links?.first?.attributes?.href?.url
						)
					} else { nil }
					
					
				}
			} ?? Array<Item>(),
			attachments: atom.entries.flatMap {
				$0.compactMap { atomEntrie in
					if let itemId = atomEntrie.id,
					   let mediaContents = atomEntrie.media?.mediaContents {
						mediaContents.compactMap { mediaContent in
							if let url = mediaContent.attributes?.url?.url,
							   let type = mediaContent.attributes?.type?.type {
								Attachment(
									feedUrl: feedUrl,
									itemId: itemId,
									url: url,
									type: type,
									title: mediaContent.mediaTitle?.value
								)
							} else { nil }
						}
					} else { nil }
				}.flatMap { $0 }
			} ?? Array<Attachment>()
		)
	}
}
