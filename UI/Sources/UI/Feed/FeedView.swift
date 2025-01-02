import SwiftUI
import Combine
import GRDBQuery
import Core

struct FeedView: View {
	@Query<Request> var feed: Feed?
	
	init(source: URL) {
		_feed = Query(
			Binding(
				get: { Request(source: source) },
				set: { _ in }
			),
			in: \.store
		)
	}
	
	var body: some View {
		if let feed {
			HStack {
				FeedIconView(source: feed.source).boxed(padded: false)
				Text(feed.title ?? feed.source.absoluteString)
					.lineLimit(1)
					.layoutPriority(-1)
			}
		}
	}
}

extension FeedView {
	struct Request: Queryable {
		static var defaultValue: Feed? = nil
		let source: URL
		
		func publisher(in store: Store) -> AnyPublisher<Feed?, Error> {
			Feed.publisherSingle(in: store, for: source)
		}
	}
}
