import SwiftUI
import QuickLook
import UniformTypeIdentifiers

struct RemoteImageView: View {
	let url: URL
	let type: UTType
	let invalidateSize: () -> Void
	@State private var quickLook: URL?
	@State private var downloadState: DownloadState?
	
	var body: some View {
		Group {
			switch downloadState {
			case nil:
				Button("Load Preview") { Task { await load() } }
					.padding()
			case let .loading(progress):
				ProgressView(value: progress)
			case let .success(data):
				Image(uiImage: UIImage(data: data) ?? UIImage(systemName: "photo")!)
					.resizable()
					.aspectRatio(contentMode: .fit)
					.quickLookPreview($quickLook)
					.onTapGesture {
						let tempUrl = FileManager.default
							.temporaryDirectory
							.appendingPathComponent("attachment", conformingTo: type)
						try? data.write(to: tempUrl)
						quickLook = tempUrl
					}
					
			case let .error(error):
				VStack {
					Text(error)
						.foregroundStyle(Color.red)
					Button("Load Preview") { Task { await load() } }
				}.padding()
			}
		}
		.task {
			invalidateSize()
			await load()
		}
	}
	
	private func load() async {
		for await state in downloadFile(from: url) {
			if case .loading = state  {
				downloadState = state
			} else {
				downloadState = state
				invalidateSize()
			}
		}
	}
}
