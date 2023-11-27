import SwiftUI

struct AttachmentView<Selector: View>: View {
	let attachment: Attachment
	@State private var aspectRatio: Double = 16 / 9
	@ObservedObject var store: Store = .shared
	@ViewBuilder var selector: () -> Selector
	
	var url: URL {
		if case let .completed(url) = store.downloads[attachment.url] {
			url
		} else {
			attachment.url
		}
	}
	
	var body: some View {
		VStack(spacing: .zero) {
			HStack {
				DownloadView(attachment: attachment)
				Text(attachment.title ?? attachment.url.lastPathComponent)
					.lineLimit(1)
					.truncationMode(.head)
				Spacer()
				selector()
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 12)
			if attachment.type.conforms(to: .image) {
				AsyncImage(url: attachment.url) {
					switch $0 {
					case .success(let image):
						image
							.resizable()
							.aspectRatio(contentMode: .fit)
					default:
						EmptyView()
					}
				}
			} else if attachment.type.conforms(to: .audiovisualContent) {
				PlayerViewController(url: url, aspectRatio: $aspectRatio)
					.aspectRatio(aspectRatio, contentMode: .fit)
			}
		}
		.background(Color(.secondarySystemBackground))
		.cornerRadius(16)
		.onAppear { checkLocalFile() }
		.onChange(of: attachment) {
			checkLocalFile()
			aspectRatio = 16 / 9
		}
	}
	
	private func checkLocalFile() {
		if FileManager.default.fileExists(
			atPath: attachment.localUrl.path
		) && store.downloads[attachment.url] == nil {
			store.downloads[attachment.url] = .completed(attachment.url)
		}
	}
}
