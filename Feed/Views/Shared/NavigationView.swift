import SwiftUI

struct NavigationView: View {
	@ObservedObject var store: Store = .shared
	@Environment(\.horizontalSizeClass) var horizontalSizeClass
	@Environment(\.scenePhase) var scenePhase
	@State var navigationSplitViewVisibility: NavigationSplitViewVisibility = .automatic
	
	var body: some View {
		NavigationSplitView(columnVisibility: $navigationSplitViewVisibility) {
			FeedsView()
		} content: {
			if let filter = store.filter {
				ItemsView(filter: filter)
			}
		} detail: {
			if let id = store.itemId {
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
		.onChange(of: scenePhase) {
			if scenePhase == .active {
				store.fetch(after: 300)
			} else {
				if let id = store.itemId { store.markAsRead(id: id) }
			}
		}
	}
}
