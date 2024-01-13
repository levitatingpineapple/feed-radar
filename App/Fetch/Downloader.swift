import Foundation

/// A simple downloader that publishes it's progress
@Observable
final class Downloader: NSObject {
	var state: State = .ready
	private var downloadTask: URLSessionDownloadTask?
	fileprivate var localUrl: URL?
	
	/// Loads file from URL. Calling this function cancels previous download task.
	///
	/// - Parameters:
	///   - url: URL to download file from
	///   - localUrl: If set, the file is written to disk after a successful download
	func load(from url: URL, localUrl: URL? = nil) {
		state = .loading(progress: .zero)
		self.localUrl = localUrl
		downloadTask = URLSession(
			configuration: .default,
			delegate: self,
			delegateQueue: nil
		).downloadTask(with: url)
		downloadTask?.resume()
	}
	
	/// Cancels existing download task and returns to initial state.
	func cancel() {
		downloadTask?.cancel()
		self.state = .ready
	}
}

extension Downloader: URLSessionDownloadDelegate {
	func urlSession(
		_ session: URLSession,
		downloadTask: URLSessionDownloadTask,
		didWriteData bytesWritten: Int64,
		totalBytesWritten: Int64,
		totalBytesExpectedToWrite: Int64
	) {
		DispatchQueue.main.async {
			self.state = .loading(
				progress: Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
			)
		}
	}

	func urlSession(
		_ session: URLSession,
		downloadTask: URLSessionDownloadTask,
		didFinishDownloadingTo location: URL
	) {
		do {
			let data = try Data(contentsOf: location)
			if let localUrl {
				try? FileManager.default.createDirectory(
					at: localUrl.deletingLastPathComponent(),
					withIntermediateDirectories: true
				)
				try? data.write(to: localUrl)
			}
			DispatchQueue.main.async { self.state = .success(data) }
		} catch {
			DispatchQueue.main.async { self.state = .error(error.localizedDescription) }
		}
	}

	func urlSession(
		_ session: URLSession,
		task: URLSessionTask,
		didCompleteWithError error: Error?
	) {
		if let error {
			DispatchQueue.main.async { self.state = .error(error.localizedDescription) }
		}
	}
}

extension Downloader {
	enum State: Equatable {
		case ready
		case loading(progress: Double)
		case success(Data)
		case error(String)
	}
}
