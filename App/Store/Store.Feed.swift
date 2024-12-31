import Foundation
import GRDB
import os.log
import FeedKit

extension Store {
	var feeds: Array<Feed> {
		(try? queue.write {
			try? Feed
				.order(Feed.Column.title.column)
				.reversed()
				.fetchAll($0)
		}) ?? Array<Feed>()
	}
	
	/// Adds feed and fetches it's items
	/// - Parameters:
	///   - feed: Feed to add
	///   - userInitiated: Only syncs is initiated by user to prevent feedback loops
	func add(feed: Feed, userInitiated: Bool = true) async {
		if await (
			try? queue.write {
				try Feed
					.filter(Column(Item.Column.source.rawValue) == feed.source)
					.isEmpty($0)
			}
		) ?? true {
			try? await queue.write { try feed.insert($0) }
			await fetch(feed: feed)
			if userInitiated { await self.sync?.added(feed) }
		}
	}
	
	/// Removes feed from database, deletes it's attachments and preferences
	/// - Parameters:
	///   - feed: Feed to remove
	///   - userInitiated: Only syncs is initiated by user to prevent feedback loops
	func delete(feed: Feed, userInitiated: Bool = true) {
		try? queue.write { let _ = try feed.delete($0) }
		[
			String.iconKey(source: feed.source),
			String.displayKey(source: feed.source),
			String.conditionalHeadersKey(source: feed.source),
		].forEach { UserDefaults.standard.removeObject(forKey: $0) }
		if userInitiated {
			Task { await self.sync?.deleted(feed) }
		}
	}
	
	/// Called when user signs out of iCloud account
	func clearAllData() {
		try? queue.write {
			let _  = try Feed.deleteAll($0)
		}
		try? FileManager.default.removeItem(
			at: URL.documents.appendingPathComponent("attachments")
		)
		if let bundleID = Bundle.main.bundleIdentifier {
			UserDefaults.standard.removePersistentDomain(forName: bundleID)
		}
	}
	
	/// Marks all filtered unread items as read and ques them for sync
	func markAllAsRead(filter: Filter) {
		let request = filter.unread.items
		
		// Fetch items before updating
		let items = (
			try? queue.write {
				try request.fetchAll($0)
			}
		) ?? Array<Item>()
		try? queue.write {
			 let updatedCount = try request.updateAll(
				$0,
				[Item.Column.isRead.column.set(to: true)]
			 )
			Logger.store.info("Marked \(updatedCount) items as read")
		}
		Task {
			for item in items { await self.sync?.updated(item) }
		}
	}
	
	/// Concurrently and consecutively fetches feeds.
	/// Runs a partial completion after each worker finishes.
	///
	/// - Parameters:
	///   - sources: List of feed URLs to fetch
	///   - workers: Number of concurrent workers to use
	///   - partialCompletion: Completion that runs after each worker finishes
	func fetch(sources: Array<URL>, workers: UInt, partialCompletion: (Data, URL) async -> Void) async {
		var toFetch = sources // TODO: Filter already loading
		await withTaskGroup(of: Result<(Data, URL), any Error>.self) { taskGroup in
			func addWorker(taskGroup: inout TaskGroup<Result<(Data, URL), any Error>>) {
				if let source = toFetch.popLast() {
					taskGroup.addTask {
						do {
							let _ = await MainActor.run {
								LoadingManager.shared.start(source: source)
							}
							let (data, response) = try await URLSession.shared.data(
								for: ConditionalHeaders(source: source)?.request
								?? URLRequest(url: source)
							)
							ConditionalHeaders(response: response, source: source)?.store()
							return Result.success((data, source))
						} catch {
							return Result.failure(error)
						}
					}
				}
			}
			(0..<workers).forEach { _ in addWorker(taskGroup: &taskGroup) }
			while let next = await taskGroup.next() {
				switch next {
				case let .success((data, source)):
					Task { @MainActor in
						try? await Task.sleep(for: .milliseconds(500))
						LoadingManager.shared.stop(source: source)
					}
					await partialCompletion(data, source)
				case let .failure(error):
					Logger.store.debug("Failed to Download \(error)")
				}
				addWorker(taskGroup: &taskGroup)
			}
		}
	}
	
	/// Fetches feed and updates the database. If no feed is provided - fetches all feeds
	func fetch(feed: Feed? = nil) async {
		await fetch(
			sources: feed.flatMap { [$0.source] } ?? self.feeds.map { $0.source },
			workers: 8
		) { data, source in
			if data.isEmpty { return } // Response body is empty if server reponds with 304 (Not Modified)
			switch FeedParser(data: data).parse() {
			case let .success(feed):
				try? queue.write {
					let mapped = Mapped(parsed: feed, from: source)
					
					// 1. If feed has changed, insert and fetch it's icon
					if mapped.feed != (
						try? Feed
							.filter(Feed.Column.source.column == source)
							.fetchOne($0)
					) {
						try? mapped.feed.upsert($0)
						Task {
							if let iconUrl = mapped.feed.icon,
							   let iconData = try? Data(contentsOf: iconUrl),
							   let icon = iconData.scaledPng {
								UserDefaults.standard.setValue(
									icon,
									forKey: .iconKey(source: mapped.feed.source)
								)
							}
						}
					}
					
					// 2. Merge fetched items with synced state (isRead, isStarred) and insert
					for content in mapped.contents {
						var item = content.item
						var itemChanged = true
						if let stored = try? Item.filter(id: content.item.id).fetchOne($0) {
							item.isRead = stored.isRead
							item.isStarred = stored.isStarred
							item.sync = stored.sync
							item.extracted = stored.extracted
							itemChanged = item != stored
						}
						if itemChanged { try? item.insert($0) }
						let _ = try Attachment
							.filter(Attachment.CodingKeys.itemId.column == item.id)
							.deleteAll($0)
						for attachment in content
							.attachments { try? attachment.insert($0) }
					}
					
					// 4. Process orphaned sync records
					Task { await self.sync?.processOrphanedRecords(for: mapped.feed) }
					
				}
			case let .failure(error):
				Logger.store.error("Parses Error \(error)")
			}
		}
	}
}
