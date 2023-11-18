import SwiftUI
import SwiftData

struct ItemsView: View {
	@Environment(\.modelContext) private var modelContext
	@Query private var items: Array<Item>
	@Binding var selection: Item?
	let showsIcon: Bool
	
	init(filter: Filter, selection: Binding<Item?>) {
		_items = filter.query
		_selection = selection
		showsIcon = filter == .all
	}
	
	var body: some View {
		List(selection: $selection) {
			ForEach(items) { item in
				NavigationLink(value: item) {
					VStack(alignment: .leading) {
						HStack {
							if showsIcon, let feed = item.feed {
								IconView(feed: feed, size: 28)
							}
							Text(item.title ?? item.id)
						}.layoutPriority(1)
						HStack {
							if let author = item.author {
								Text(author)
							}
							Spacer()
							if let date = item.date {
								Text(date, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
							}
						}.font(.caption).foregroundColor(.secondary)
					}
				}
			}
		}.listStyle(.plain)
	}
}
