import SwiftUI
import GRDBQuery

struct FeedsView: View {
	@Query(Feed.Request(), in: \.store) private var feeds: Array<Feed>
	@ObservedObject var store: Store = .shared
	
	var body: some View {
		List(selection: $store.filter) {
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
				ForEach(feeds, id: \.url) { feed in
					NavigationLink(value: Filter.feed(feed)) {
						FeedView(url: feed.url)
					}
					.swipeActions(edge: .leading, allowsFullSwipe: true) {
						Button("Fetch") {
							Store.shared.fetch(.feed(feed))
						}.tint(.accentColor)
					}
				}
				.onDelete {
					$0.forEach { Store.shared.delete(feed: feeds[$0]) }
				}
			}
		}
		.toolbar {
			ToolbarItem {
				ImportView()
			}
		}
		.refreshable { Store.shared.fetch(.all) }
		.navigationTitle("Feeds")
	}
}
