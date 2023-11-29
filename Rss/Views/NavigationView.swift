import SwiftUI

struct NavigationView: View {
	@ObservedObject var store: Store = .shared
	@Environment(\.horizontalSizeClass) var horizontalSizeClass
	@State var navigationSplitViewVisibility: NavigationSplitViewVisibility = .automatic
	
	var body: some View {
		NavigationSplitView(columnVisibility: $navigationSplitViewVisibility) {
			FeedsView()
		} content: {
			if let filter = store.filter {
				ItemsView(filter: filter)
			}
		} detail: {
			if let item = store.item {
				ItemDetailView(item: item)
			}
		}
		.task {
			navigationSplitViewVisibility = horizontalSizeClass == .regular
			? .all
			: .automatic
			store.fetch()
		}
	}
}
