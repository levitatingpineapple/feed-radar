import SwiftUI
import GRDBQuery

struct FeedsView: View {
	@Query(Feed.Request(), in: \.store) private var feeds: Array<Feed>
	@ObservedObject var store: Store = .shared
	@State private var isImportPresented = false
	
	var body: some View {
		List(selection: $store.filter) {
			Section {
				NavigationLink(value: Filter()) {
					FilterView(filter: Filter())
				}
				NavigationLink(value: Filter(isRead: false)) {
					FilterView(filter: Filter(isRead: false))
				}
				NavigationLink(value: Filter(isStarred: true)) {
					FilterView(filter: Filter(isStarred: true))
				}
			}
			Section {
				ForEach(feeds, id: \.source) { feed in
					NavigationLink(value: Filter(feed: feed)) {
						FilterView(filter: Filter(feed: feed))
					}
					.swipeActions(edge: .leading, allowsFullSwipe: true) {
						Button("Fetch") {
							Task { await Store.shared.fetch(feed: feed) }
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
				SystemImageButton(systemName: "plus", color: .accentColor) {
					isImportPresented = true
				}.popover(isPresented: $isImportPresented) {
					FeedImportView()
				}
			}
		}
		.refreshable { await Store.shared.fetch() }
		.navigationTitle("Feeds")
	}
}
