import SwiftUI

extension EnvironmentValues {
	private struct StoreKey: EnvironmentKey {
		static var defaultValue: Store { .shared }
	}
	
	var store: Store {
		get { self[StoreKey.self] }
		set { self[StoreKey.self] = newValue }
	}
}

@main
struct RssApp: App {
	@ObservedObject var store: Store = .shared
	
	var body: some Scene {
		WindowGroup {
			NavigationSplitView(columnVisibility: .constant(.all)) {
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
			.task { Store.shared.fetch() }
		}
	}
}
