import Foundation
import os.log
import Combine

/// Handles feed fetching state and order.
actor FeedFetcher {
	private var loadingSubjects = Dictionary<URL, CurrentValueSubject<Bool, Never>>()
	
	/// Returns a publisher that emits download status for a given feed.
	///
	/// - Parameter source: Source URL of the feed
	/// - Returns: Download's state publisher
	func isLoading(source: URL) -> CurrentValueSubject<Bool, Never> {
		if let publisher = loadingSubjects[source] {
			return publisher
		} else {
			loadingSubjects[source] = CurrentValueSubject<Bool, Never>(false)
			return isLoading(source: source)
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
		var toFetch = sources.filter { isLoading(source: $0).value == false }
		await withTaskGroup(of: Result<(Data, URL), any Error>.self) { taskGroup in
			func addWorker(taskGroup: inout TaskGroup<Result<(Data, URL), any Error>>) {
				if let source = toFetch.popLast() {
					Task { @MainActor in
						await self.isLoading(source: source).send(true)
					}
					taskGroup.addTask {
						do {
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
						// Wait a bit to make sure loading spinner has faded in
						try? await Task.sleep(for: .milliseconds(200))
						await self.isLoading(source: source).send(false)
					}
					await partialCompletion(data, source)
				case let .failure(error): Logger.store.debug("Failed to Download \(error)")
				}
				addWorker(taskGroup: &taskGroup)
			}
		}
	}
}
