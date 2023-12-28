import XCTest
@testable import Feed

final class FeedTests: XCTestCase {
	private let store = try! Store(isTesting: true)

	func testFetch() async throws {
		if let source = Bundle(for: type(of: self))
			.url(forResource: "MockFeed", withExtension: "json") {
			await store.fetch(feed: Feed(source: source))
			assert(store.feeds.count == 1)
		} else {
			XCTFail("Missing file: MockFeed.json")
		}
	}
	
}

