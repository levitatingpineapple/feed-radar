import SwiftUI

struct StoreKey: EnvironmentKey {
	static let defaultValue = try! Store()
}

extension EnvironmentValues {
	var store: Store {
		get { self[StoreKey.self] }
	}
}

@main
struct AppLauncher {
	static func main() throws {
		NSClassFromString("XCTestCase") == nil
			? FeedRadarApp.main()
			: TestApp.main()
	}
}

struct TestApp: App {
	var body: some Scene {
		WindowGroup {
			VStack {
				Image(.rss)
				Text("Running unit tests…")
				ProgressView()
			}
		}
	}
}

struct FeedRadarApp: App {
	var body: some Scene {
		WindowGroup { NavigationView() }
	}
}
