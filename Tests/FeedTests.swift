import XCTest
@testable import FeedRadar

import AVKit

final class FeedTests: XCTestCase {
	
	// MARK: Test Store
	private let store = try! Store(testName: "A")
	
	private var source: URL {
		Bundle(for: type(of: self)).url(forResource: "feed", withExtension: "json")!
	}
	
	private var item: Item {
		store.item(id: (source.absoluteString + "0").stableHash)!
	}
	
	override func setUp() async throws {
		await store.add(feed: Feed(source: source))
		// TODO: Check why async fetch is returning before everything has been fetched.
		try await Task.sleep(nanoseconds: 100_000_000)
	}
	
	func testFeeds() {
		XCTAssert(store.feeds.count == 1)
	}
	
	func testToggleRead() {
		let isRead = item.isRead
		store.toggleRead(for: item)
		XCTAssert(item.isRead == !isRead)
	}
	
	func testToggleStarred() {
		let isStarred = item.isStarred
		store.toggleStarred(for: item)
		XCTAssert(item.isStarred == !isStarred)
	}
	
	func testMarkAsRead() {
		store.markAsRead(itemId: item.id)
		XCTAssert(item.isRead)
		store.markAsRead(itemId: item.id)
		XCTAssert(item.isRead)
	}
	
	func testTouchedItems() {
		store.toggleRead(for: item)
		XCTAssert(store.touchedItems.contains(item))
	}
	
	func testAttachmentsCount() {
		XCTAssert(store.attachments(itemId: item.id)?.count == 2)
	}
	
	func testDeleteFeed() throws {
		if let feed = store.feeds.first {
			store.delete(feed: feed)
			XCTAssert(store.feeds.count == .zero)
			// Deleting feed should also delete it's items and attachments
			// as they are refrenced using foreign keys
			XCTAssert(try store.queue.write { try Item.fetchCount($0) } == .zero)
			XCTAssert(try store.queue.write { try Attachment.fetchCount($0) } == .zero)
		} else {
			XCTFail("Missing Feed")
		}
	}
	
	// MARK: Test Media
	
	var asset: AVAsset {
		AVAsset(url: Bundle(for: type(of: self)).url(forResource: "podcast", withExtension: "mp3")!)
	}
	
	func testMetadata() async throws {
		let metadata = try await asset.metadata()
		XCTAssert(metadata?.count == 14)
	}
	
	func testAssetArtwork() async throws {
		let artwork = try await asset.artwork()
		XCTAssert(artwork?.size == CGSize(width: 1500, height: 1500))
	}
}
