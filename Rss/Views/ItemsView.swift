import SwiftUI
import GRDBQuery

struct ItemsView: View {
	let filter: Filter
	@Query<Item.Request> var items: Array<Item>
	@ObservedObject var store: Store = .shared
	
	init(filter: Filter) {
		self.filter = filter
		_items = Query(
			Binding(get: { Item.Request(filter: filter) }, set: { _ in }),
			in: \.store
		)
	}
	
	var body: some View {
		List(items) { item in
			ZStack {
				// Hiding disclosure indicator
				NavigationLink {
					ItemView(item: item)
				} label: {
					EmptyView()
				}.opacity(.zero)
				VStack(alignment: .leading, spacing: 8) {
					if filter == .all { FeedView(url: item.feedUrl) }
					Text(item.title ?? item.itemId).bold()
					HStack {
						if let time = item.time {
							Text(
								Date(timeIntervalSince1970: time),
								format: Date.FormatStyle(date: .abbreviated, time: .shortened)
							)
						}
						Spacer()
						if let author = item.author { Text(author) }
					}.font(.caption).foregroundColor(.secondary)
				}
			}
		}
		.refreshable { Store.shared.fetch(store.filter ?? .all) }
		.listStyle(.plain)
		.navigationTitle(title)
		.toolbar {
			ToolbarItem(placement: .principal) {
				if case let .feed(feed) = filter {
					FeedView(url: feed.url)
				} else {
					Text("All")
				}
				
			}
		}
		
		.navigationBarTitleDisplayMode(.inline)
	}
	
	var title: String {
		switch filter {
		case .all: "All"
		case let .feed(feed): feed.title ?? feed.url.absoluteString
		}
	}
}
