import SwiftUI

struct NavigationView: View {
	@Environment(\.store) var store: Store
	@Environment(\.scenePhase) var scenePhase
	@Environment(\.horizontalSizeClass) var horizontalSizeClass
	@StateObject var navigation = Navigation(store: StoreKey.defaultValue)
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
				ItemDeatilWrapperView(id: id)
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
		.environmentObject(navigation)
		.onChange(of: scenePhase) {
			if scenePhase == .active {
				store.fetch(after: 300)
			} else {
				if let id = navigation.itemId { store.markAsRead(itemId: id) }
			}
		}
	}
}
