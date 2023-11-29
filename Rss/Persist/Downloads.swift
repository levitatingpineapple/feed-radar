import SwiftUI

class Downloads: ObservableObject {
	@Published var tasks = Dictionary<URL, Download>()
	
	static let shared = Downloads()
	
	func download(attachment: Attachment) {
		if tasks.keys.contains(attachment.url) { return }
		var observation: NSKeyValueObservation!
		let dataTask = URLSession.shared.dataTask(with: URLRequest(url: attachment.url)) { data, _, _ in
			if let data {
				try! FileManager.default.createDirectory(
					at: attachment.localUrl.deletingLastPathComponent(),
					withIntermediateDirectories: true
				)
				try! data.write(to: attachment.localUrl)
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
		observation = dataTask.progress.observe(\.fractionCompleted) { progress, test in
			DispatchQueue.main.async {
				self.tasks[attachment.url] = .progress(progress.fractionCompleted)
			}
		}
		dataTask.resume()
	}
}

extension Downloads {
	enum Download: Equatable {
		case progress(Double)
		case completed(URL)
		case error
	}
}

