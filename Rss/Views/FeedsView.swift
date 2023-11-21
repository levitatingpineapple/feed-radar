import SwiftUI
import GRDBQuery

struct FeedsView: View {
	@Query(Feed.Request(), in: \.store) private var feeds: Array<Feed>
	@Binding var filter: Filter?
	
	var body: some View {
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
				ForEach(feeds, id: \.url) { feed in
					FeedView(feed: feed)
						.swipeActions(edge: .leading, allowsFullSwipe: true) {
							Button("Fetch") {
								Store.shared.fetch(.feed(feed))
							}.tint(.accentColor)
						}
				}
				.onDelete {
					$0.forEach { feed in
						// TODO: Delete
					}
				}
			}
		}
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				Button {
					Store.shared.fetch(.all)
				} label: {
					Label("Reload", systemImage: "arrow.clockwise")
				}
			}
			ToolbarItem {
				ImportView()
			}
		}
		.refreshable { Store.shared.fetch(.all) }
		.navigationTitle("Feeds")
	}
}
