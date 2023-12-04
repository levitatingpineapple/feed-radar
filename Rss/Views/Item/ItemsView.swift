import SwiftUI
import GRDBQuery

struct ItemsView: View {
	let filter: Item.Filter
	@Query<Item.Request> var items: Array<Item>
	@ObservedObject var store: Store = .shared
	@State private var isFilterSettingsPresented = false
	
	init(filter: Item.Filter) {
		self.filter = filter
		_items = Query(
			Binding(get: { Item.Request(filter: filter) }, set: { _ in }),
			in: \.store
		)
	}
	
	var body: some View {
		List(items, selection: $store.item) { item in
			ItemView(item: item, showsFeed: filter.feed == nil)
		}
		.refreshable { await Store.shared.test(feed: store.filter?.feed) }
		.animation(.default, value: items)
		.listStyle(.plain)
		.navigationTitle(filter.title)
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .principal) {
				FilterView(filter: filter, isCompact: true).bold()
			}
			ToolbarItem(placement: .topBarTrailing) {
				SystemImageButton(systemName: "line.3.horizontal.decrease") {
					isFilterSettingsPresented = true
				}.popover(isPresented: $isFilterSettingsPresented) {
					FilterSettingsView()
				}
			}
		}
	}
}
