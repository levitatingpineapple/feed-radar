import Foundation
import os.log

class Fetcher: ObservableObject {
	static let shared = Fetcher() // TODO: Inject as environment object
	
	@Published var tasks = Set<URL>()
	
	func process(sources: Array<URL>, workers: UInt, partialCompletion: (Data, URL) async -> Void) async {
		var toFetch = sources.filter { !tasks.contains($0) }
		await withTaskGroup(of: Result<(Data, URL), any Error>.self) { taskGroup in
			func addWorker() {
				if let source = toFetch.popLast() {
					DispatchQueue.main.async { self.tasks.insert(source) }
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
			(0..<workers).forEach { _ in addWorker() }
			while let next = await taskGroup.next() {
				switch next {
				case let .success((data, source)):
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.tasks.remove(source) }
					await partialCompletion(data, source)
				case let .failure(error): Logger.store.debug("Failed to Download \(error)")
				}
				addWorker()
			}
		}
	}
}
