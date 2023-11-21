import SwiftUI

struct FeedView: View {
	let feed: Feed
	
	var body: some View {
		NavigationLink(value: Filter.feed(feed)) {
			Label {
				HStack {
					Text(feed.title ?? feed.url.absoluteString)
					Spacer()
					
					// TODO: Add fetching
//					if feed.isFetching {
//						ProgressView().controlSize(.small)
//					}
				}
			} icon: {
				IconView(feed: feed, size: 28)
			}
		}
	}
}
