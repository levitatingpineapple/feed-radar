import SwiftUI
import GRDBQuery

struct FeedListView: View {
	@Query(Feed.RequestAll(), in: \.store) private var feeds: Array<Feed>
	@Environment(\.store) var store: Store
	@Environment(Navigation.self) var navigation
	@State private var isImportPresented = false
	
	private func link(filter: Filter) -> some View {
		NavigationLink(value: filter) { FilterView(filter: filter) }
	}
	
	var body: some View {
		@Bindable var navigation = navigation
		List(selection: $navigation.filter) {
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
							Task { await store.fetch(feed: feed) }
						}.tint(.accentColor)
					}
				}
				.onDelete {
					$0.forEach { store.delete(feed: feeds[$0]) }
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
		.refreshable { await store.fetch() }
		.navigationTitle("Feeds")
	}
}
