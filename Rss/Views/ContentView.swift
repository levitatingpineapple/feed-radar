import SwiftUI
import SwiftData

import AVKit

struct ContentView: View {
	@Environment(\.modelContext) private var modelContext
	@Query private var feeds: Array<Feed>
	@State private var filter: Filter? = .all
	@State private var item: Item?
	
	var body: some View {
		NavigationSplitView() {
			List(selection: $filter) {
				Section {
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
				}
				Section {
					ForEach(feeds) { feed in
						FeedView(feed: feed)
							.swipeActions(edge: .leading, allowsFullSwipe: true) {
								Button("Fetch") {
									Task { await fetch(feed: feed) }
								}.tint(.accentColor)
							}
					}
					.onDelete { $0.forEach { modelContext.delete(feeds[$0]) } }
				}
			}
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button {
						Task { await fetch() }
					} label: {
						Label("Reload", systemImage: "arrow.clockwise")
					}
				}
				ToolbarItem {
					ImportView()
				}
			}
			.refreshable { await fetch() }
			.navigationTitle("Feeds")
		} content: {
			if let filter {
				ItemsView(filter: filter, selection: $item)
					.navigationTitle(filter.title)
					.navigationBarTitleDisplayMode(.inline)
			}
		} detail: {
			if let item = item {
				ItemView(item: item)
			}
		}
		.task { await fetch() }
	}
	
	@MainActor
	private func fetch(feed: Feed? = nil) async {
		let feedsToFetch = feed
			.flatMap { [$0] } ?? feeds.filter { $0.isFetching == false }
		feedsToFetch.forEach { $0.isFetching = true }
		for feed in feedsToFetch {
			if let items = try? await Array<Item>(url: feed.url) {
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
