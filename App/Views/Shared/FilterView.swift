import SwiftUI
import GRDBQuery

struct FilterView: View {
	typealias TintedImage = ModifiedContent<Image, _ForegroundStyleModifier<Color>>
	let filter: Filter
	let isCompact: Bool
	let primaryImage: TintedImage
	let secondaryImage: TintedImage?
	let tertiaryImage: TintedImage?
	
	@Environment(\.store) var store: Store
	
	init(filter: Filter, isCompact: Bool = false) {
		self.filter = filter
		self.isCompact = isCompact
		
		var feedImage: TintedImage? {
			filter.feed
				.flatMap { _ in Image(.rss).renderingMode(.template) }
				.flatMap { $0.resizable().foregroundStyle(Color.primary) as? TintedImage }
		}
		
		var inboxImage: TintedImage? {
			if filter.feed == nil && (filter.isRead == nil) == (filter.isStarred == nil) {
				return Image(systemName: "tray.fill").resizable()
					.foregroundStyle(Color.purple) as? TintedImage
			} else {
				return nil
			}
		}
		
		var isReadImage: TintedImage? {
			filter.isRead.flatMap {
				Image(systemName: $0 ? "circle" : "circle.fill").resizable()
					.foregroundStyle(Color.accentColor) as? TintedImage
			}
		}
		
		var isStarredImage: TintedImage? {
			filter.isStarred.flatMap {
				Image(systemName: $0 ? "star.fill" : "star" ).resizable()
					.foregroundStyle(Color.orange) as? TintedImage
			}
		}
		
		let images = [feedImage, inboxImage, isReadImage, isStarredImage].compactMap { $0 }
		primaryImage = images.first! // There must always be a primary image
		secondaryImage = images.count > 1 ? images[1] : nil
		tertiaryImage = images.count > 2 ? images[2] : nil
	}
	
	var icon: some View {
		ZStack(alignment: .topTrailing) {
			ZStack {
				if let feed = filter.feed {
					FeedIconView(source: feed.source).boxed(padded: false)
				} else {
					primaryImage.boxed()
				}
			}.boxed(padded: filter.feed == nil)
			HStack(spacing: 2) {
				if let tertiaryImage { tertiaryImage.scaledToFit() }
				if let secondaryImage { secondaryImage.scaledToFit() }
			}
			.frame(height: 12)
			.transformEffect(.init(translationX: 6, y: -6))
			.shadow(color: Color(.systemBackground), radius: 8)
		}
	}
	
	func countView(filter: Filter, color: Color) -> some View {
		CountView(filter: filter)
		.background(color)
		.clipShape(Capsule())
	}
	
	var body: some View {
		HStack(spacing: 8) {
			icon
			Text(filter.title).lineLimit(1).layoutPriority(-1)
			if !isCompact { Spacer() }
			if filter.feed != nil || filter.isRead == false {
				countView(filter: filter.unread, color: .accentColor.opacity(0.8))
			} else if filter.isStarred == true {
				countView(filter: filter, color: .orange.opacity(0.6))
			}
		}
		.contentShape(Rectangle())
		.contextMenu(
			ContextMenu {
				if let feed = filter.feed {
					Button {
						Task { await store.fetch(feed: feed) }
					} label: { Label("Fetch", systemImage: "arrow.clockwise") }
					Button {
						UIPasteboard.general.url = feed.source
					} label: { Label("Copy Link", systemImage: "doc.on.doc") }
				}
				Button {
					store.markAllAsRead(filter: filter)
				} label: { Label("Mark all as read", systemImage: "circle") }
			}
		)
	}
}
