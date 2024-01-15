import Foundation
import FeedKit
import UniformTypeIdentifiers

/// A type that maps various decoded feed types into one
struct Mapped {
	struct Content {
		let item: Item
		let attachments: Array<Attachment>
	}
	
	let feed: Feed
	let contents: Array<Content>
	
	init(parsed: FeedKit.Feed, from source: URL) {
		switch parsed {
		
		// MARK: Atom
		case let .atom(atom):
			feed = Feed(
				source: source,
				title: atom.title,
				icon: atom.icon?.url ??
				(atom.links?.first?.attributes?.href?.url ?? source).favicon
			)
			contents = atom.entries?.compactMap { atomEntrie in
				atomEntrie.id.flatMap { atomEntrieId in
					Content(
						item: Item(
							id: (source.absoluteString + atomEntrieId).stableHash,
							source: source,
							title: atomEntrie.title ?? atomEntrieId,
							time: (atomEntrie.updated ?? atomEntrie.published)?.timeIntervalSince1970,
							author: atomEntrie.authors?
								.compactMap { $0.name?.trimmingCharacters(in: .whitespacesAndNewlines) }
								.joined(separator: ", "),
							content: atomEntrie.content?.value,
							url: atomEntrie.links?.first?.attributes?.href?.url
						),
						attachments: atomEntrie.media?.mediaContents?.compactMap { mediaContent in
							if let url = mediaContent.attributes?.url?.url,
							   let type = mediaContent.attributes?.type {
								Attachment(
									itemId: (source.absoluteString + atomEntrieId).stableHash,
									url: url,
									mime: type,
									title: mediaContent.mediaTitle?.value
								)
							} else { nil }
						} ?? Array<Attachment>()
					)
				}
			} ?? Array<Content>()
		
		// MARK: Rss
		case let .rss(rss):
			feed = Feed(
				source: source,
				title: rss.title,
				icon: rss.image?.url?.url
				?? rss.iTunes?.iTunesImage?.attributes?.href?.url
				?? (rss.link?.url ?? source).favicon
			)
			contents = rss.items?.compactMap { rssItem in
				rssItem.guid?.value.flatMap { guid in
					let itemId = (source.absoluteString + guid).stableHash
					let enclosure: Array<Attachment>? =
						if let url = rssItem.enclosure?.attributes?.url?.url,
						   let type = rssItem.enclosure?.attributes?.type {
							[Attachment(itemId: itemId, url: url, mime: type, title: nil)]
						} else { nil }
					let mediaContents: Array<Attachment>? = rssItem.media?.mediaContents?.compactMap { mediaContent in
						if let url = mediaContent.attributes?.url?.url,
						   let type = mediaContent.attributes?.type {
							Attachment(
								itemId: itemId,
								url: url,
								mime: type,
								title: mediaContent.mediaDescription?.value
							)
						} else { nil }
					}
					return Content(
						item: Item(
							id: itemId,
							source: source,
							title: rssItem.title ?? guid,
							time: rssItem.pubDate?.timeIntervalSince1970,
							author: rssItem.author ?? rssItem.dublinCore?.dcCreator,
							content: rssItem.content?.contentEncoded ?? rssItem.description,
							url: rssItem.link?.url
						),
						attachments: mediaContents ?? enclosure ?? Array<Attachment>()
					)
				}
			} ?? Array<Content>()
			
		// MARK: Json
		case let .json(json):
			feed = Feed(
				source: source,
				title: json.title,
				icon: json.favicon?.url ?? json.icon?.url
				?? (json.feedUrl?.url ?? json.homePageURL?.url ?? source).favicon
			)
			contents = json.items?.compactMap { jsonItem in
				jsonItem.id.flatMap { jsonItemId in
					let itemId = (source.absoluteString + jsonItemId).stableHash
					return Content(
						item: Item(
							id: itemId,
							source: source,
							title: jsonItem.title ?? jsonItemId,
							time: (jsonItem.dateModified ?? jsonItem.datePublished)?.timeIntervalSince1970,
							author: jsonItem.author?.name,
							content: jsonItem.contentHtml ?? jsonItem.contentText,
							url: jsonItem.url?.url
						),
						attachments: jsonItem.attachments?.compactMap { attachment in
							if let url = attachment.url?.url,
							   let type = attachment.mimeType {
								Attachment(
									itemId: itemId,
									url: url,
									mime: type,
									title: attachment.title
								)
							} else { nil }
						} ?? Array<Attachment>()
					)
				}
			} ?? Array<Content>()
		}
	}
}
