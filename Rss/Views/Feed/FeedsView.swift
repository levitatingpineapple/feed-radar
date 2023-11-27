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
				ForEach(feeds, id: \.source) { feed in
					NavigationLink(value: Item.Filter.feed(feed)) {
						FilterView(filter: .feed(feed))
					}
					.swipeActions(edge: .leading, allowsFullSwipe: true) {
						Button("Fetch") {
							Store.shared.fetch(source: feed.source)
						}.tint(.accentColor)
					}
				}
				.onDelete {
					$0.forEach { index in
						let feed = feeds[index]
						Store.shared.delete(feed: feed)
					}
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
