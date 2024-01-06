import SwiftUI
import GRDBQuery

struct ItemListView: View {
	let filter: Filter
	@State var isFilterSettingsPresented = false
	@EnvironmentObject var navigation: Navigation
	@Environment(\.store) var store: Store
	@Query<Item.RequestIDs> var itemIds: Array<Item.ID>
	
	init(filter: Filter) {
		self.filter = filter
		_itemIds = Query(
			Binding(
				get: { Item.RequestIDs(filter: filter) },
				set: { _ in }
			),
			in: \.store
		)
	}
	
	var body: some View {
		List(itemIds, id: \.self, selection: $navigation.itemId) { id in
			LazyItemView(showsFeed: filter.feed == nil, id: id)
		}
		.refreshable { await store.fetch(feed: navigation.filter?.feed) }
		.animation(.default, value: itemIds)
		.listStyle(.plain)
		.navigationTitle(filter.title)
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .principal) {
				FilterView(filter: filter, isCompact: true).bold()
			}
			ToolbarItem(placement: .topBarTrailing) {
				SystemImageButton(systemName: "line.3.horizontal.decrease", color: .accentColor) {
					isFilterSettingsPresented = true
				}.popover(isPresented: $isFilterSettingsPresented) {
					FilterSettingsView()
				}
			}
		}
	}
}
