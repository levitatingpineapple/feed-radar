import SwiftUI
import GRDBQuery

struct FeedView: View {
	let source: URL
	@Query<Feed.RequestSingle> var feed: Feed?
	@AppStorage var icon: Data?
	
	var image: Image? {
		icon
			.flatMap { UIImage(data: $0) }
			.flatMap { Image(uiImage: $0) }
	}
	
	init(source: URL) {
		self.source = source
		_feed = Query(
			Binding(
				get: { Feed.RequestSingle(source: source) },
				set: { _ in }
			),
			in: \.store
		)
		_icon = AppStorage(.iconKey(source: source))
	}
	
	var body: some View {
		if let feed {
			HStack {
				(image ?? Image(.rss).renderingMode(.template))
					.resizable().boxed(padded: false)
				Text(feed.title ?? feed.source.absoluteString).lineLimit(1).layoutPriority(-1)
			}
		}
	}
}
