import SwiftUI
import GRDBQuery

struct FeedsView: View {
	@Query(Feed.Request(), in: \.store) private var feeds: Array<Feed>
	@ObservedObject var store: Store = .shared
	@State private var isImportPresented = false
	
	private func link(filter: Filter) -> some View {
		NavigationLink(value: filter) { FilterView(filter: filter) }
	}
	
	var body: some View {
		List(selection: $store.filter) {
			Section {
				link(filter: Filter())
				link(filter: Filter(isRead: false))
				link(filter: Filter(isStarred: true))
			}
			Section {
				ForEach(feeds, id: \.source) { feed in
					link(filter: Filter(feed: feed))
					.swipeActions(edge: .leading, allowsFullSwipe: true) {
						Button("Fetch") {
							Task { await Store.shared.fetch(feed: feed) }
						}.tint(.accentColor)
					}
				}
				.onDelete {
					$0.forEach {
						Store.shared.delete(feed: feeds[$0])
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
