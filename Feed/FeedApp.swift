import SwiftUI

extension EnvironmentValues {
	private struct StoreKey: EnvironmentKey {
		static let defaultValue = try! Store()
	}
	
	var store: Store {
		get { self[StoreKey.self] }
		set { self[StoreKey.self] = newValue }
	}
}

@main
struct AppLauncher {
	static func main() throws {
		NSClassFromString("XCTestCase") == nil
			? FeedApp.main()
			: TestApp.main()
	}
}

struct TestApp: App {
	var body: some Scene {
		WindowGroup {
			VStack {
				Image(.rss)
				Text("Testing")
				ProgressView()
			}
		}
	}
}

struct FeedApp: App {
	@StateObject var store = try! Store()
	
	var body: some Scene {
		WindowGroup { NavigationView().environmentObject(store) }
	}
}
