import SwiftUI
import QuickLook
import CryptoKit


// TODO: Add stop
// TODO: For downloading - check if already exists
// TODO: Add retry
struct DownloadView: View {
	let size: Double
	let type: UTType
	
	enum Model: Equatable {
		case remote(URL)
		case progress(Double)
		case local(URL)
		case error
	}
	
	@State private var model: Model
	@State private var quickLook: URL?
	@State private var dataTask: URLSessionDataTask?
	@State private var observation: NSKeyValueObservation?
	
	init(size: Double, type: UTType, url: URL) {
		self.size = size
		self.type = type
		_model = State(initialValue: .remote(url))
	}
	
	var body: some View {
		Group {
			switch model {
			case .remote:
				Button {
					download()
				} label: {
					Image(systemName: "arrow.down.circle").resizable().scaledToFit()
				}
			case let .progress(progress):
				CircularProgressView(width: size / 10, progress: progress)
			case let .local(url):
				Button {
					quickLook = url
				} label: {
					Image(systemName: "eye").resizable().scaledToFit()
				}.quickLookPreview($quickLook)
			case .error:
				Image(systemName: "exclamationmark.circle").resizable().scaledToFit().foregroundColor(.red)
			}
		}.frame(width: size, height: size).animation(.default, value: model)
	}
	
	private func download() {
		if case let .remote(url) = model {
			model = .progress(.zero)
			dataTask = URLSession.shared.dataTask(with: url) { data, _, _ in
				if let data {
					let hash = SHA256
						.hash(data: data)
						.compactMap { String(format: "%02x", $0) }
						.joined()
					
					let directoryUrl = FileManager.default
						.temporaryDirectory
						.appendingPathComponent(hash)
					
					let fileUrl = directoryUrl
						.appendingPathComponent(url.lastPathComponent, conformingTo: type)

					try! FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: true)
					try! data.write(to: fileUrl)
					print(fileUrl)
					DispatchQueue.main.async {
						model = .local(fileUrl)
						quickLook = fileUrl
					}
				} else {
					DispatchQueue.main.async { model = .error }
				}
			}
			observation = dataTask?.progress.observe(\.fractionCompleted) { progress, _ in
				DispatchQueue.main.async { model = .progress(progress.fractionCompleted) }
			}
			dataTask?.resume()
		}
	}
}
