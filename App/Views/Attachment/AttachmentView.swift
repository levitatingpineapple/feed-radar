import SwiftUI
import QuickLook

struct AttachmentView: View {
	let item: Item
	let attachment: Attachment
	let invalidateSize: () -> Void
	@Environment(\.store) var store: Store
	@State private var quickLook: URL?
	@State private var downloader = Downloader()
	
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
	}
	
	var quickLookButton: some View {
		Button {
			quickLook = attachment.localUrl
		} label: {
			Image(systemName: "eye").resizable().scaledToFit()
		}.quickLookPreview($quickLook)
	}
	
	var progressButton: some View {
		Group {
			if url == attachment.url {
				switch downloader.state {
				case .ready:
					Button {
						downloader.load(from: attachment.url, localUrl: attachment.localUrl)
					} label: {
						Image(systemName: "arrow.down.circle").resizable().scaledToFit()
					}
				case let .loading(progress):
					CircularProgressView(width: 24 / 10, progress: progress)
						.contentShape(Rectangle())
						.onTapGesture { downloader.cancel() }
				case .success:
					quickLookButton
				case .error:
					Button {
						downloader.load(from: attachment.url, localUrl: attachment.localUrl)
					} label: {
						Image(systemName: "exclamationmark.circle").resizable().scaledToFit()
							.foregroundColor(.red)
					}
				}
			} else {
				quickLookButton
			}
		}.frame(width: 24, height: 24)
	}
	
	var mediaPreview: some View {
		Group {
			if attachment.type.conforms(to: .image) {
				RemoteImageView(
					url: url,
					type: attachment.type,
					invalidateSize: invalidateSize
				)
			} else if attachment.type.conforms(to: .audiovisualContent) {
				PlayerView(
					invalidateSize: invalidateSize,
					model: PlayerView.Model(url: url, item: item)
				)
			}
		}
		.clipShape(UnevenRoundedRectangle(topLeadingRadius: 15, topTrailingRadius: 15))
		.padding(1)
	}
	
	var url: URL {
		switch downloader.state {
		case .loading:
			attachment.url
		default:
			if FileManager.default.fileExists(atPath: attachment.localUrl.path) {
				attachment.localUrl
			} else {
				attachment.url
			}
		}
	}
}
