import SwiftUI
import GRDBQuery

struct FeedView: View {
	@Query<Feed.RequestSingle> var feed: Feed?
	
	init(source: URL) {
		_feed = Query(
			Binding(
				get: { Feed.RequestSingle(source: source) },
				set: { _ in }
			),
			in: \.store
		)
	}
	
	var body: some View {
		if let feed {
			HStack {
				FeedIconView(source: feed.source).boxed(padded: false)
				Text(feed.title ?? feed.source.absoluteString).lineLimit(1).layoutPriority(-1)
			}
		}
	}
}

struct FeedIconView: View {
	@AppStorage var iconData: Data?
	
	init(source: URL) {
		_iconData = AppStorage(.iconKey(source: source))
	}
	
	var body: Image {
		iconData
			.flatMap { UIImage(data: $0) }
			.flatMap { Image(uiImage: $0).resizable() }
		?? Image(.rss).renderingMode(.template).resizable()
	}
}
