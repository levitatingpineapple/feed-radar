import SwiftUI
import GRDBQuery

struct ItemsView: View {
	let filter: Item.Filter
	@AppStorage("isReadFiltered") var isReadFiltered = false
	@Query<Item.Request> var items: Array<Item>
	@ObservedObject var store: Store = .shared
	
	init(filter: Item.Filter) {
		self.filter = filter
		_items = Query(
			Binding(get: { Item.Request(filter: filter) }, set: { _ in }),
			in: \.store
		)
	}
	
	var filtred: Array<Item> { items.filter { !($0.isRead && isReadFiltered) } }
	
	var body: some View {
		List(items, selection: $store.item) { item in
			ItemView(item: item, showsFeed: filter == .unread || filter == .starred)
		}
		.animation(.easeOut(duration: 0.2), value: filtred)
		.refreshable { Store.shared.fetch(source: store.filter?.source) }
		.listStyle(.plain)
		.navigationTitle(navigationTitle)
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .principal) {
				FilterView(filter: filter, isCompact: true).bold()
			}
			ToolbarItem(placement: .topBarTrailing) {
				Button{
					// TODO: Open Settings
				} label: {
					Image(systemName: "gear")
				}
			}
		}
		
	}
	
	var navigationTitle: String {
		switch filter {
		case .unread: "Unread"
		case .starred: "Starred"
		case .feed(let feed): feed.title ?? feed.source.absoluteString
		}
	}
}
