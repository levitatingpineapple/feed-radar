import SwiftUI

struct FeedView: View {
	@Environment(\.modelContext) private var modelContext
	@ObservedObject var feed: Feed
	
	var body: some View {
		NavigationLink(value: Filter.feed(feed)) {
			Label {
				HStack {
					Text(feed.title ?? feed.url.absoluteString)
					Spacer()
					if feed.isFetching {
						ProgressView().controlSize(.small)
					}
				}
			} icon: {
				IconView(feed: feed, size: 28)
			}
		}
	}
}
