import SwiftUI

/// A View that handles ``Navigation``
/// It explicitly switches to using `NavigationStack` in compact mode
/// to address animation issues with related to `NavigationSplitView` and Large Titles
struct NavigationView: View {
	@Environment(\.store) var store: Store
	@Environment(\.scenePhase) var scenePhase
	@Environment(\.horizontalSizeClass) var horizontalSizeClass
	@State var navigation = Navigation(store: StoreKey.defaultValue)
	@State var navigationSplitViewVisibility: NavigationSplitViewVisibility = .automatic

	var body: some View {
		NavigationSplitView(columnVisibility: $navigationSplitViewVisibility) {
			FeedListView()
		} content: {
			if let filter = navigation.filter {
				ItemListView(filter: filter)
			}
		} detail: {
			if let id = navigation.itemId {
				ItemDetailWrapperView(id: id)
			}
		}
		.task {
			store.fetch(after: 300)
			navigationSplitViewVisibility = horizontalSizeClass == .regular
			? .all
			: .automatic
			let _ = try? await UNUserNotificationCenter
				.current()
				.requestAuthorization(options: .badge)
		}
		.environment(navigation)
		.onChange(of: scenePhase) {
			if scenePhase == .active {
				store.fetch(after: 300)
			} else {
				if let id = navigation.itemId { store.markAsRead(itemId: id) }
			}
		}
	}
}
