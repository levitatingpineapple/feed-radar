import SwiftUI

struct RemoteImageView: View {
	let url: URL
	let invalidateSize: () -> Void
	@StateObject private var downloader = Downloader()
	
	var body: some View {
		Group {
			switch downloader.state {
			case .ready:
				Button("Load Preview") { downloader.load(from: url) }
					.padding()
			case let .loading(progress):
				ProgressView(value: progress)
			case let .success(data):
				Image(uiImage: UIImage(data: data) ?? UIImage(systemName: "photo")!)
					.resizable()
					.aspectRatio(contentMode: .fit)
			case let .error(error):
				VStack {
					Text(error)
						.foregroundStyle(Color.red)
					Button("Load Preview") { downloader.load(from: url) }
				}.padding()
			}
		}
		.onAppear { downloader.load(from: url) }
		.onChange(of: url) { downloader.load(from: url) }
		.onChange(of: downloader.state) { invalidateSize() }
	}
}
