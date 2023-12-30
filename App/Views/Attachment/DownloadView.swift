import SwiftUI
import QuickLook
import CryptoKit

// TODO: Add stop
// TODO: Add retry
struct DownloadView: View {
	let attachment: Attachment
	@ObservedObject var attachments: AttachmentsFetcher = .shared
	@State private var quickLook: URL?

	var body: some View {
		Group {
			if let download = attachments.tasks[attachment.url] {
				switch download {
				case let .progress(progress):
					CircularProgressView(width: 24 / 10, progress: progress)
				case let .completed(url):
					Button {
						quickLook = url
					} label: {
						Image(systemName: "eye").resizable().scaledToFit()
					}.quickLookPreview($quickLook)
				case .error:
					Image(systemName: "exclamationmark.circle").resizable().scaledToFit()
						.foregroundColor(.red)
				}
			} else {
				Button {
					attachments.download(attachment: attachment)
				} label: {
					Image(systemName: "arrow.down.circle").resizable().scaledToFit()
				}
			}
		}.frame(width: 24, height: 24)
	}
}
