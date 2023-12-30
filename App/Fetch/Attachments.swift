import SwiftUI

class Attachments: ObservableObject {
	static let shared = Attachments()
	@Published var tasks = Dictionary<URL, Task>()
	
	/// Downloads an attachment to user's documents directory.
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
	
	func load(local attachment: Attachment) {
		if FileManager.default.fileExists(atPath: attachment.localUrl.path)
		   && tasks[attachment.url] == nil {
			tasks[attachment.url] = .completed(attachment.localUrl)
		}
	}
	
	func remove(local attachment: Attachment) {
		tasks.removeValue(forKey: attachment.url)
		try? FileManager.default
			.removeItem(at: attachment.localUrl.deletingLastPathComponent())
	}
}

extension Attachments {
	enum Task: Equatable {
		case progress(Double)
		case completed(URL)
		case error
	}
}
