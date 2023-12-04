import SwiftUI
import GRDBQuery

struct FeedsView: View {
	@Query(Feed.Request(), in: \.store) private var feeds: Array<Feed>
	@ObservedObject var store: Store = .shared
	
	var body: some View {
		List(selection: $store.filter) {
			Section {
				NavigationLink(value: Item.Filter()) {
					FilterView(filter: Item.Filter())
				}
				NavigationLink(value: Item.Filter(isRead: false)) {
					FilterView(filter: Item.Filter(isRead: false))
				}
				NavigationLink(value: Item.Filter(isStarred: true)) {
					FilterView(filter: Item.Filter(isStarred: true))
				}
			}
			Section {
				ForEach(feeds, id: \.source) { feed in
					NavigationLink(value: Item.Filter(feed: feed)) {
						FilterView(filter: Item.Filter(feed: feed))
					}
					.swipeActions(edge: .leading, allowsFullSwipe: true) {
						Button("Fetch") {
							Store.shared.fetch(feed: feed)
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
