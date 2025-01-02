import Foundation

public enum DownloadState: Sendable {
	case loading(progress: Double, downloadTask: URLSessionDownloadTask)
	case success(localUrl: URL)
	case error(String)
	
	public var isLoading: Bool {
		switch self {
		case .loading: true
		default: false
		}
	}
}

public func downloadFile(from remoteUrl: URL, to localUrl: URL) -> AsyncStream<DownloadState> {
	AsyncStream { continuation in
		let downloadTask = URLSession(
			configuration: .default,
			delegate: DownloadDelegate(
				continuation: continuation,
				localUrl: localUrl
			),
			delegateQueue: nil
		)
		.downloadTask(with: remoteUrl)
		continuation.yield(.loading(progress: .zero, downloadTask: downloadTask))
		downloadTask.resume()
	}
}

private final class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
	let continuation: AsyncStream<DownloadState>.Continuation
	let localUrl: URL
	
	init(
		continuation: AsyncStream<DownloadState>.Continuation,
		localUrl: URL
	) {
		self.continuation = continuation
		self.localUrl = localUrl
	}
	
	func urlSession(
		_ session: URLSession,
		downloadTask: URLSessionDownloadTask,
		didWriteData bytesWritten: Int64,
		totalBytesWritten: Int64,
		totalBytesExpectedToWrite: Int64
	) {
		let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
		continuation.yield(.loading(progress: progress, downloadTask: downloadTask))
	}
	
	func urlSession(
		_ session: URLSession,
		downloadTask: URLSessionDownloadTask,
		didFinishDownloadingTo location: URL
	) {
		do {
			try FileManager.default.createDirectory(
				at: localUrl.deletingLastPathComponent(),
				withIntermediateDirectories: true
			)
			try FileManager.default.moveItem(
				atPath: location.path,
				toPath: localUrl.path()
			)
			continuation.yield(.success(localUrl: localUrl))
		} catch {
			continuation.yield(.error(error.localizedDescription))
		}
		continuation.finish()
	}
	
	func urlSession(
		_ session: URLSession,
		task: URLSessionTask,
		didCompleteWithError error: Error?
	) {
		continuation.yield(.error(error?.localizedDescription ?? "Error downloading file"))
		continuation.finish()
	}
}
