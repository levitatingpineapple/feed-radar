import Foundation
import FeedKit
import UniformTypeIdentifiers

extension Mapped {
	init(_ atom: AtomFeed, at source: URL) {
		self = Mapped(
			feed: Feed(
				source: source,
				title: atom.title,
				icon: atom.icon?.url ?? 
				(atom.links?.first?.attributes?.href?.url ?? source).favicon
			),
			items: atom.entries.flatMap {
				$0.compactMap { atomEntrie in
					atomEntrie.id.flatMap { itemId in
						Item(
							id: (source.absoluteString + itemId).stableHash,
							source: source,
							title: atomEntrie.title ?? itemId,
							time: (atomEntrie.updated ?? atomEntrie.published)?.timeIntervalSince1970,
							author: atomEntrie.authors?
								.compactMap { $0.name?.trimmingCharacters(in: .whitespacesAndNewlines) }
								.joined(separator: ", "),
							content: atomEntrie.content?.value,
							url: atomEntrie.links?.first?.attributes?.href?.url
						)
					}
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
									id: (source.absoluteString + itemId).stableHash,
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
