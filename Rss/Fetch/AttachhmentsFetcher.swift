import SwiftUI

class AttachhmentsFetcher: ObservableObject {
	static let shared = AttachhmentsFetcher() // TODO: Inject as an environment object
	
	@Published var tasks = Dictionary<URL, Task>()
	
	func download(attachment: Attachment) {
		if tasks.keys.contains(attachment.url) { return }
		self.tasks[attachment.url] = .progress(.zero)
		var observation: NSKeyValueObservation!
		let dataTask = URLSession.shared.dataTask(with: URLRequest(url: attachment.url)) { data, _, _ in
			if let data {
				try? FileManager.default.createDirectory(
					at: attachment.localUrl.deletingLastPathComponent(),
					withIntermediateDirectories: true
				)
				try? data.write(to: attachment.localUrl)
				DispatchQueue.main.async {
					observation.invalidate()
					self.tasks[attachment.url] = .completed(attachment.localUrl)
				}
			} else {
				DispatchQueue.main.async {
					observation.invalidate()
					self.tasks[attachment.url] = .error
				}
			}
		}
		observation = dataTask.progress.observe(\.fractionCompleted) { progress, change in
			DispatchQueue.main.async {
				self.tasks[attachment.url] = .progress(progress.fractionCompleted)
			}
		}
		dataTask.resume()
	}
}

extension AttachhmentsFetcher {
	enum Task: Equatable {
		case progress(Double)
		case completed(URL)
		case error
	}
}
