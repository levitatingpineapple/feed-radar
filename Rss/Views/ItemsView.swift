import SwiftUI
import GRDBQuery

struct ItemsView: View {
	@Query<Item.Request> var items: Array<Item>
	@Binding var item: Item?
	
	init(request: Item.Request, item: Binding<Item?>) {
		_item = item
		_items = Query(
			Binding(get: { request }, set: { _ in }),
			in: \.store
		)
	}
	
	var body: some View {
		List(selection: $item) {
			ForEach(items) { item in
				ZStack {
					NavigationLink(value: item) {
						EmptyView()
					}.opacity(.zero)
					
					HStack(spacing: 8) {
						VStack(alignment: .leading) {
							Text(item.title ?? item.itemId)
							HStack {
								if let author = item.author {
									Text(author)
								}
								Spacer()
								if let time = item.time {
									Text(
										Date(
											timeIntervalSince1970: time),
										format: Date.FormatStyle(date: .abbreviated, time: .shortened))
								}
							}.font(.caption).foregroundColor(.secondary)
						}
					}
				}
				
				

			}
		}
		.listStyle(.plain)
		.navigationTitle(title)
		.navigationBarTitleDisplayMode(.inline)
	}
	
	var title: String {
		switch $items.request.filter.wrappedValue {
		case .all: "All"
		case let .feed(feed): feed.title ?? feed.url.absoluteString
		}
	}
}
