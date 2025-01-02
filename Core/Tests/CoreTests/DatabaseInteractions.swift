import Testing
import Foundation
@testable import Core

@Suite
struct DatabaseInteractions {
	@Test
	func main() async throws {
		let source = Bundle.module.url(forResource: "feed", withExtension: "json")!
		let store = try Store(testName: "Test")

		var first: Item { 
			store.item(id: (source.absoluteString + "first").stableHash)! 
		}

		var second: Item { 
			store.item(id: (source.absoluteString + "second").stableHash)! 
		}

		// Adding feed
		await store.add(feed: Feed(source: source))
		#expect(
			store.feeds.count == 1,
			"There should be feed added to the database"
		)

		// Toggling read
		let isRead = first.isRead
		store.toggleRead(for: first)
		#expect(
			first.isRead == !isRead,
			"Read state sould be toggled"
		)

		// Toggle starred
		let isStarred = first.isStarred
		store.toggleStarred(for: first)
		#expect(
			first.isStarred == !isStarred,
			"Starred state should be toggled"
		)

		// Check that the item has been interacted with
		#expect(store.touchedItems.contains(first))
		#expect(!store.touchedItems.contains(second))
		
		store.delete(feed: store.feeds.first!)
		
		#expect(
			store.feeds.count == .zero,
			"Deleting Feed must remove it from database"
		)
		#expect(
			try await store.queue.write { try Item.fetchCount($0) } == .zero,
			"Items should be removed due to foreign key reference to `Feed`"
		)
		#expect(
			try await store.queue.write { try Attachment.fetchCount($0) } == .zero,
			"Attachments should be removed due to foreign key reference to `Item`"
		)
	}
}
