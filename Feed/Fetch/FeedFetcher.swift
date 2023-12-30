import Foundation
import os.log
import Combine


/// Handles feed fetching state and order.
///
/// # UI Optimization
/// [Navigation](Navigation.swift#L8)
/// ### Another
class FeedFetcher {
	
	/// Global instance
	static let shared = FeedFetcher()
	
	private var loadingSubjects = Dictionary<URL, CurrentValueSubject<Bool, Never>>()
	
	/// Returns a publisher that emits download status for a given feed.
	///
	/// - Parameter source: Source URL of the feed
	/// - Returns: Dwnload state publisher
	func isLoading(source: URL) -> CurrentValueSubject<Bool, Never> {
		if let publisher = loadingSubjects[source] {
			return publisher
		} else {
			loadingSubjects[source] = CurrentValueSubject<Bool, Never>(false)
			return isLoading(source: source)
		}
	}
	
	/// Concurently and consequetively fetches feeds. Running a partial completion after each worker finishes.
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
					DispatchQueue.main.async {
						self.isLoading(source: source).send(true)
					}
					taskGroup.addTask {
						do {
							return Result.success(
								(try await URLSession(configuration: .default).data(from: source).0, source)
							)
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
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
						self.isLoading(source: source).send(false)
					}
					await partialCompletion(data, source)
				case let .failure(error): Logger.store.debug("Failed to Download \(error)")
				}
				addWorker(taskGroup: &taskGroup)
			}
		}
	}
}
