import XCTest
@testable import FeedRadar

import AVKit

final class FeedTests: XCTestCase {
	
	private var bundle: Bundle { Bundle(for: type(of: self)) }
	
	// MARK: Test Store
	
	private var feedSource: URL {
		bundle.url(forResource: "feed", withExtension: "json")!
	}
	
	private var item: Item {
		store.item(id: (feedSource.absoluteString + "0").stableHash)!
	}
	
	private lazy var store: Store = {
		let store = try! Store(testName: "A")
		let group = DispatchGroup()
		group.enter()
		Task {
			await store.add(feed: Feed(source: feedSource))
			// TODO: Fetch is returning before result has been stored?
			try! await Task.sleep(nanoseconds: 100_000_000)
			group.leave()
		}
		group.wait()
		return store
	}()
	
	override func setUp() async throws {
		
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
			XCTAssert(
				try store.queue.write { try Item.fetchCount($0) } == .zero,
				"Items should be removed due to foreign key refrence to `Feed`"
			)
			XCTAssert(
				try store.queue.write { try Attachment.fetchCount($0) } == .zero,
				"Atachments should be removed due to foreign key refrence to `Item`"
			)
		} else {
			XCTFail("Missing Feed")
		}
	}
	
	// MARK: Test Metadata
	
	func testMetadataLoader() async throws {
		let metadataLoader = MetadataLoader()
		let metadata = try await metadataLoader.metadata(
			url: bundle.url(forResource: "podcast", withExtension: "mp3")!
		)
		XCTAssert(metadata.artwork?.size == CGSize(width: 1500, height: 1500))
		XCTAssert(metadata.chapters.count == 6)
		XCTAssert(metadata.chapters[4].title == "Rambo\'s New Mac")
		XCTAssert(metadata.chapters[4].artwork?.size == CGSize(width: 1024, height: 1024))
	}
	
	func testChaptersFromTextValid() {
		XCTAssert(
			Array<Metadata.Chapter>(
				description: "0:00 A<br>0:01 B<br>0:02 C<br>0:03 D"
			) == [
				Metadata.Chapter(startTime: 0, endTime: 1, title: "A", artwork: nil),
				Metadata.Chapter(startTime: 1, endTime: 2, title: "B", artwork: nil),
				Metadata.Chapter(startTime: 2, endTime: 3, title: "C", artwork: nil),
				Metadata.Chapter(startTime: 3, endTime: 3, title: "D", artwork: nil)
			],
			"These chapters should be valid"
		)
	}
	
	func testChaptersFromTextEmptyLine() {
		XCTAssert(
			Array<Metadata.Chapter>(
				description: "0:00 A<br>0:01 B<br>0:02 C<br>0:03 D<br>NOT A CHAPTER<br>0:04 E"
			) == [
				Metadata.Chapter(startTime: 0, endTime: 1, title: "A", artwork: nil),
				Metadata.Chapter(startTime: 1, endTime: 2, title: "B", artwork: nil),
				Metadata.Chapter(startTime: 2, endTime: 3, title: "C", artwork: nil),
				Metadata.Chapter(startTime: 3, endTime: 3, title: "D", artwork: nil)
			],
			"Decoding must stop at first line, which is not a chapter"
		)
	}
	
	func testChaptersFromTextStartTime() {
		XCTAssert(
			Array<Metadata.Chapter>(
				description: "0:01 A<br>0:02 B<br>0:03 C<br>0:04 D"
			) == nil,
			"Chapters must start from 0:00"
		)
	}
	
	func testChaptersFromTextOrdering() {
		XCTAssert(
			Array<Metadata.Chapter>(
				description: "0:01 A<br>0:03 B<br>0:02 C<br>0:04 D"
			) == nil,
			"Chapters must be ordered"
		)
	}
	
	func testChaptersFromTextOrderingTimeFormatting() {
		XCTAssert(
			Array<Metadata.Chapter>(
				description: "0:00 A<br>12:34 B<br>1:23:45 C<br>12:34:56 D"
			) == [
				Metadata.Chapter(startTime: 0, endTime: 754, title: "A", artwork: nil),
				Metadata.Chapter(startTime: 754, endTime: 5025, title: "B", artwork: nil),
				Metadata.Chapter(startTime: 5025, endTime: 45296, title: "C", artwork: nil),
				Metadata.Chapter(startTime: 45296, endTime: 45296, title: "D", artwork: nil)
			],
			"Chapters can have various time formatting"
		)
	}
	
	func testChaptersFromTextOrderingSamples() {
		let descriptions = try! String(
			contentsOf: bundle.url(forResource: "descriptions", withExtension: "html")!
		).components(separatedBy: .newlines)
		for (description, chaptersCount) in zip(descriptions, [42, 5, 7]) {
			XCTAssert(
				Array<Metadata.Chapter>(
					description: description
				)?.count == chaptersCount,
				"Description sample chapter count should match"
			)
		}
	}
	
	// MARK: Test Conditional Get
	
	func testConditionalHeadersEtag() {
		let source = URL(string: "https://source.com")!
		ConditionalHeaders(
			response: HTTPURLResponse(
				url: URL(string: "https://response.com")!,
				statusCode: 200,
				httpVersion: nil,
				headerFields: ["etag": "W/\"3kkoIUL-kj3827\""]
			)!,
			source: source
		)?.store()
		let request = ConditionalHeaders(source: source)?.request
		XCTAssert(
			request?.value(forHTTPHeaderField: "if-modified-since") == nil,
			"`if-modified-since` request header should match `last-modified` response header"
		)
		XCTAssert(
			request?.value(forHTTPHeaderField: "if-none-match") == "W/\"3kkoIUL-kj3827\"",
			"`if-none-match` request header should match `etag` response header, including escaped quotes"
		)
	}
	
	func testConditionalHeadersLastModified() {
		let source = URL(string: "https://source.com")!
		ConditionalHeaders(
			response: HTTPURLResponse(
				url: URL(string: "https://response.com")!,
				statusCode: 200,
				httpVersion: nil,
				headerFields: [
					"last-modified": "1 Jan 2023 11:01:56 GMT",
					"etag": "W/\"3kkoIUL-kj3827\""
				]
			)!,
			source: source
		)?.store()
		let request = ConditionalHeaders(source: source)?.request
		XCTAssert(
			request?.value(forHTTPHeaderField: "if-modified-since") == "1 Jan 2023 11:01:56 GMT",
			"`if-modified-since` request header should match `last-modified` response header"
		)
		XCTAssert(
			request?.value(forHTTPHeaderField: "if-none-match") == nil,
			"If `last-modified` is present, etag sould not be used."
		)
	}
}


