import SwiftUI
import Combine
import GRDBQuery
import Core

struct ItemListView: View {
	let filter: Filter
	@State var isFilterSettingsPresented = false
	@Environment(Navigation.self) var navigation
	@Environment(\.store) var store: Store
	@Query<Request> var itemIds: Array<Item.ID>
	
	init(filter: Filter) {
		self.filter = filter
		_itemIds = Query(
			Binding(
				get: { Request(filter: filter) },
				set: { _ in }
			),
			in: \.store
		)
	}
	
	var body: some View {
		@Bindable var navigation = navigation
		List(itemIds, id: \.self, selection: $navigation.itemId) { id in
			ZStack {
				NavigationLink(value: id) { EmptyView() }.opacity(.zero)
				ItemView(id: id, showsFeed: filter.feed == nil)
			}
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

extension ItemListView {
	struct Request: Queryable {
		static var defaultValue = Array<Int64>()
		
		public let filter: Filter
		
		func publisher(in store: Store) -> AnyPublisher<Array<Int64>, Error> {
			Item.publisherIDs(in: store, filter: filter)
		}
	}
}
