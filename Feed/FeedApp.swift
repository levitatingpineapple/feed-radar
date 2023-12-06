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
struct FeedApp: App {
	var body: some Scene {
		WindowGroup { NavigationView() }
	}
}
