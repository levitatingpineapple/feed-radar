import SwiftUI
import GRDBQuery

struct FeedView: View {
	let url: URL
	@Query<Feed.RequestSingle> var feed: Feed?
	@ObservedObject var store: Store = .shared
	
	init(url: URL) {
		self.url = url
		_feed = Query(
			Binding(
				get: { Feed.RequestSingle(url: url) },
				set: { _ in }
			),
			in: \.store
		)
	}
	
	var isFetching: Bool {
		store.fetching.contains(url)
	}
	
	var body: some View {
		if let feed {
			HStack {
				ZStack {
					IconView(feed: feed)
						.blur(radius: isFetching ? 2 : 0)
						.opacity(isFetching ? 0.4 : 1)
					ProgressView()
						.frame(width: 32, height: 32)
						.opacity(isFetching ? 1 : 0)
				}.animation(.easeInOut(duration: 0.2), value: isFetching)
				Text(feed.title ?? feed.source.absoluteString).lineLimit(1)
			}.contextMenu(
				ContextMenu {
					Button {
						Store.shared.fetch(feed: feed)
					} label: { Label("Fetch", systemImage: "arrow.clockwise") }
					Button {
						UIPasteboard.general.url = feed.source
					} label: { Label("Copy Link", systemImage: "doc.on.doc") }
					Button {
						Store.shared.markAllAsRead(feed: feed)
					} label: { Label("Mark all as read", systemImage: "circle") }
					Button(role: .destructive ) {
						Store.shared.removeAttachments(source: feed.source)
					} label: { Label("Remove attachments", systemImage: "paperclip") }
				}
			)
		}
	}
}
