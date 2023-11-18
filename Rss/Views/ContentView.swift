import SwiftUI
import SwiftData

struct ContentView: View {
	@Environment(\.modelContext) private var modelContext
	@Query private var feeds: Array<Feed>
	@State private var filter: Filter?
	@State private var item: Item?
	
	private func fetch() async {
		let feedsToFetch = feeds.filter { $0.isFetching == false }
		DispatchQueue.main.async {
			feedsToFetch.forEach { $0.isFetching = true }
		}
		for feed in feedsToFetch {
			if let items = try? await Array<Item>(url: feed.url) {
				DispatchQueue.main.sync {
					items.forEach { item in
						if let index = feed.items.firstIndex(where: { $0.id == item.id }) {
							modelContext.delete(feed.items[index])
						}
						modelContext.insert(item)
						feed.items.append(item)
					}
					feed.isFetching = false
				}
			}
		}
	}
	
	private var placement: ToolbarItemPlacement {
#if os(iOS)
		ToolbarItemPlacement.topBarLeading
#elseif os(macOS)
		ToolbarItemPlacement.automatic
#endif
	}
	
	private func delete(offsets: IndexSet) {
		offsets.forEach {
			modelContext.delete(feeds[$0])
		}
	}
	
	var body: some View {
		NavigationSplitView {
			List(selection: $filter) {
				NavigationLink(value: Filter.all) {
					Label {
						Text("All")
					} icon: {
						Image(systemName: "tray.fill")
							.resizable()
							.scaledToFit()
							.frame(maxWidth: 28, maxHeight: 28)
					}
				}
				ForEach(feeds) { feed in
					FeedView(feed: feed)
				}
				.onDelete(perform: delete)
			}
			.toolbar {
				ToolbarItem(placement: placement) {
					Button {
						Task { await fetch() }
					} label: {
						Label("Reload", systemImage: "arrow.clockwise")
					}
				}
				
			}
			.refreshable { await fetch() }
			.navigationTitle("Feeds")
		} content: {
			if let filter {
				ItemsView(filter: filter, selection: $item)
					.navigationTitle(filter.title)
#if os(iOS)
					.navigationBarTitleDisplayMode(.inline)
#endif
			}
		} detail: {
			if let item = item {
				ItemView(item: item)
			}
		}
	}
}

struct FeedView: View {
	@Environment(\.modelContext) private var modelContext
	@ObservedObject var feed: Feed
	
	var body: some View {
		NavigationLink(value: Filter.feed(feed)) {
			Label {
				HStack {
					Text(feed.title ?? feed.url.absoluteString)
					Spacer()
					if feed.isFetching { ProgressView().controlSize(.regular) }
				}
				
			} icon: {
				IconView(feed: feed, size: 28)
			}
		}
		.swipeActions(edge: .leading, allowsFullSwipe: true) {
			Button("Fetch", action: fetch).tint(.accentColor)
		}
	}
	
	private func fetch() {
		feed.isFetching = true
		Task {
			if let items = try? await Array<Item>(url: feed.url) {
				DispatchQueue.main.async {
					items.forEach { item in
						if let index = feed.items.firstIndex(where: { $0.id == item.id }) {
							modelContext.delete(feed.items[index])
						}
						modelContext.insert(item)
						feed.items.append(item)
					}
				}
			}
			feed.isFetching = false
		}
	}
}
