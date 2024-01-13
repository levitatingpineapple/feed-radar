import SwiftUI

/// A Key for accessing the ``Store`` from the environment.
struct StoreKey: EnvironmentKey {
	static let defaultValue = try! Store()
}

extension EnvironmentValues {
	var store: Store {
		get { self[StoreKey.self] }
	}
}

/// Entry point for the app.
/// Selects between ``FeedRadarApp`` and ``TestApp``
@main struct AppLauncher {
	static func main() throws {
		NSClassFromString("XCTestCase") == nil
			? FeedRadarApp.main()
			: TestApp.main()
	}
}

/// The main app
struct FeedRadarApp: App {
	@State private var feedUrl: URL?
	@Environment(\.store) private var store: Store
	
	var body: some Scene {
		WindowGroup {
			NavigationView()
				.onOpenURL {
					feedUrl = URL(string: $0.absoluteString.strippingPrefix("feed:"))
				}
				.alert(
					"Import Feed?\n" + (feedUrl?.absoluteString ?? String()),
					isPresented: Binding(
						get: { feedUrl != nil },
						set: { if !$0 { feedUrl = nil } }
					)
				) {
					Button("Import") {
						if let source = feedUrl {
							Task { await store.add(feed: Feed(source: source)) }
							feedUrl = nil
						}
					}
				}
		}
	}
}

/// An app that displays simple UI while running unit tests.
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
