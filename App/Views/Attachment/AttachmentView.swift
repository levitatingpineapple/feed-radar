import SwiftUI
import QuickLook

struct AttachmentView: View {
	var attachment: Attachment
	let invalidateSize: () -> Void
	@State private var quickLook: URL?
	@Environment(\.store) var store: Store
	@EnvironmentObject var navigation: Navigation
	@StateObject private var downloader = Downloader()
	@StateObject private var chapterCoordinator = PlayerViewController.ChapterCoordinator()
	
	var body: some View {
		VStack(spacing: .zero) {
			mediaPreview
			HStack(alignment: .bottom) {
				Text(attachment.title ?? attachment.url.lastPathComponent)
					.frame(minHeight: 24)
				Spacer()
				progressButton
			}
			.padding(10)
		}
		.background(Color(.secondarySystemBackground))
		.cornerRadius(16)
		.onChange(of: attachment) { chapterCoordinator.aspectRatio = nil }
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
				VStack(spacing: .zero) {
					PlayerViewController(
						url: url,
						item: navigation.itemId.flatMap { store.item(id: $0) },
						chapterCoordinator: chapterCoordinator
					)
					.aspectRatio(chapterCoordinator.aspectRatio ?? 16 / 9, contentMode: .fit)
					ChaptersView(chapterCoordinator: chapterCoordinator)
				}
				.onChange(of: chapterCoordinator.aspectRatio) { invalidateSize() }
				.onChange(of: chapterCoordinator.metadata) { invalidateSize() }
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
