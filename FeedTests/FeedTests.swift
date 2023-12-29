import XCTest
@testable import Feed

final class FeedTests: XCTestCase {
	private let store = try! Store(testName: "A")
	
	private var source: URL {
		Bundle(for: type(of: self)).url(forResource: "feed", withExtension: "json")!
	}
	
	private var item: Item {
		store.item(id: (source.absoluteString + "0").stableHash)!
	}
	
	override func setUp() async throws {
		await store.add(feed: Feed(source: source))
	}
	
	func testFeeds() {
		assert(store.feeds.count == 1)
	}
	
	func testToggleRead() {
		let isRead = item.isRead
		store.toggleRead(for: item)
		assert(item.isRead == !isRead)
	}
	
	func testToggleStarred() {
		let isStarred = item.isStarred
		store.toggleStarred(for: item)
		assert(item.isStarred == !isStarred)
	}
	
	func testMarkAsRead() {
		store.markAsRead(id: item.id)
		assert(item.isRead)
		store.markAsRead(id: item.id)
		assert(item.isRead)
	}
	
	func testTouchedItems() {
		store.toggleRead(for: item)
		assert(store.touchedItems.contains(item))
	}
	
	func testAttachments() {
		assert(store.attachments(id: item.id)?.count == 2)
	}
}
