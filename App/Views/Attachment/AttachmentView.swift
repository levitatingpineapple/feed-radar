import SwiftUI
import QuickLook

struct AttachmentView: View {
	let item: Item
	let attachment: Attachment
	let invalidateSize: () -> Void
	@Environment(\.store) var store: Store
	@State private var quickLook: URL?
	@State private var downloadState: DownloadState?
	
	var body: some View {
		VStack(spacing: .zero) {
			mediaPreview
			HStack(alignment: .bottom) {
				Text(attachment.title ?? attachment.localUrl.lastPathComponent)
					.frame(minHeight: 24)
				Spacer()
				progressButton
			}
			.padding(10)
		}
		.background(Color(.secondarySystemBackground))
		.cornerRadius(16)
		.task {
			invalidateSize()
			if FileManager.default.fileExists(atPath: attachment.localUrl.path) {
				downloadState = .success(localUrl: attachment.localUrl)
			} else if attachment.preview == .image {
				await load()
			}
		}
	}
	
	private var progressButton: some View {
		Group {
			switch downloadState {
			case nil:
				Button(action: load) {
					Image(systemName: "arrow.down.circle")
						.resizable()
						.scaledToFit()
				}
			case let .loading(progress, downloadTask):
				CircularProgressView(width: 24 / 10, progress: progress)
					.contentShape(Rectangle())
					.onTapGesture { downloadTask.cancel() }
			case .success:
				Button {
					quickLook = attachment.localUrl
				} label: {
					Image(systemName: "eye").resizable().scaledToFit()
				}
				.quickLookPreview($quickLook)
			case .error:
				Button(action: load) {
					Image(systemName: "exclamationmark.circle")
						.resizable()
						.scaledToFit()
						.foregroundColor(.red)
				}
			}
		}
		.frame(width: 24, height: 24)
	}
	
	private var mediaPreview: some View {
		Group {
			switch downloadState {
			case nil:
				if let preview = attachment.preview {
					switch preview {
					case .image:
						Button("Load Preview", action: load).padding()
					case .video:
						PlayerView(
							invalidateSize: invalidateSize,
							model: PlayerView.Model(
								url: attachment.url,
								item: item
							)
						)
					}
				}
			case let .loading(progress, _):
				ProgressView(value: progress)
			case let .success(url):
				if let preview = attachment.preview {
					switch preview {
					case .image:
						if let data = try? Data(contentsOf: url),
						   let uiImage = UIImage(data: data) {
							Image(uiImage: uiImage)
								.resizable()
								.aspectRatio(contentMode: .fit)
								.quickLookPreview($quickLook)
								.onTapGesture { quickLook = url }
						}
					case .video:
						PlayerView(
							invalidateSize: invalidateSize,
							model: PlayerView.Model(
								url: url,
								item: item
							)
						)
					}
				}
			case let .error(string):
				VStack {
					Text(string).foregroundStyle(Color.red)
					Button("Load Preview", action: load).padding()
				}
				.padding()
			}
		}
		.clipShape(UnevenRoundedRectangle(topLeadingRadius: 15, topTrailingRadius: 15))
		.padding(1)
	}
	
	private func load() {
		Task { await load() }
	}
	
	private func load() async {
		for await state in downloadFile(from: attachment.url, to: attachment.localUrl)  {
			let skipLayout = state.isLoading && downloadState?.isLoading == true
			downloadState = state
			if !skipLayout { invalidateSize() }
		}
	}
}
