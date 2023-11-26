import SwiftUI
import GRDBQuery

struct FeedsView: View {
	@Query(Feed.Request(), in: \.store) private var feeds: Array<Feed>
	@ObservedObject var store: Store = .shared
	
	var body: some View {
		List(selection: $store.filter) {
			Section {
				NavigationLink(value: Item.Filter.unread) {
					FilterView(filter: .unread)
				}
				NavigationLink(value: Item.Filter.starred) {
					FilterView(filter: .starred)
				}
			}
			Section {
				ForEach(feeds, id: \.url) { feed in
					NavigationLink(value: Item.Filter.feed(feed)) {
						FilterView(filter: .feed(feed))
					}
					.swipeActions(edge: .leading, allowsFullSwipe: true) {
						Button("Fetch") {
							Store.shared.fetch(feedUrl: feed.url)
						}.tint(.accentColor)
					}
				}
				.onDelete {
					$0.forEach { Store.shared.delete(feed: feeds[$0]) }
				}
			}
		}
		.toolbar {
			ToolbarItem {
				FeedImportView()
			}
		}
		.refreshable { Store.shared.fetch() }
		.navigationTitle("Feeds")
	}
}
