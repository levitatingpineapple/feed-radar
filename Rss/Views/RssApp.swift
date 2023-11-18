import SwiftUI
import SwiftData

@main
struct RssApp: App {
	static let modelContainer: ModelContainer = {
		let schema = Schema([Item.self, Feed.self])
		do {
			return try ModelContainer(
				for: schema,
				configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]
			)
		} catch {
			fatalError("Could not create ModelContainer: \(error)")
		}
	}()
	
	var body: some Scene {
		WindowGroup {
			ContentView()
		}.modelContainer(Self.modelContainer)
	}
}
