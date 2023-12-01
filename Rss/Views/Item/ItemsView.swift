import SwiftUI
import GRDBQuery

struct ItemsView: View {
	let filter: Item.Filter
	@AppStorage(.isReadFilteredKey) var isReadFiltered = false
	@Query<Item.Request> var items: Array<Item>
	@ObservedObject var store: Store = .shared
	
	init(filter: Item.Filter) {
		self.filter = filter
		_items = Query(
			Binding(get: { Item.Request(filter: filter) }, set: { _ in }),
			in: \.store
		)
	}
	
	var filtered: Array<Item> { items.filter { !($0.isRead && isReadFiltered) } }
	
	var body: some View {
		List(filtered, selection: $store.item) { item in
			ItemView(item: item, showsFeed: filter == .unread || filter == .starred)
		}
		.refreshable { Store.shared.fetch(feed: store.filter?.feed) }
		.animation(.easeOut(duration: 0.2), value: filtered)
		.listStyle(.plain)
		.navigationTitle(filter.navigationTitle)
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .principal) {
				FilterView(filter: filter, isCompact: true).bold()
			}
			ToolbarItem(placement: .topBarTrailing) {
				SystemImageButton(
					systemName: isReadFiltered ? "circle.fill" : "circle"
				) { isReadFiltered.toggle() }
			}
		}
	}
}
