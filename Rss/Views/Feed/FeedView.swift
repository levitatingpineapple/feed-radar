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
					IconView(feed: feed, size: 32)
						.blur(radius: isFetching ? 2 : 0)
						.opacity(isFetching ? 0.4 : 1)
					ProgressView()
						.frame(width: 32, height: 32)
						.opacity(isFetching ? 1 : 0)
				}
				Text(feed.title ?? feed.url.absoluteString).lineLimit(1)
			}
		}
	}
}
