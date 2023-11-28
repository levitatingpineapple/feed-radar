import SwiftUI

struct AttachmentView<Selector: View>: View {
	let attachment: Attachment
	@State private var aspectRatio: Double = 16 / 9
	@ObservedObject var downloads: Downloads = .shared
	@ViewBuilder var selector: () -> Selector
	
	var url: URL {
		if case let .completed(url) = downloads.tasks[attachment.url] {
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
			}.padding(10)
			Group {
				if attachment.type.conforms(to: .image) {
					AsyncImage(url: url) {
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
					VStack {
						PlayerViewController(url: url, aspectRatio: $aspectRatio)
							.aspectRatio(aspectRatio, contentMode: .fit)
					}
					
				}
			}.clipShape(
				UnevenRoundedRectangle(bottomLeadingRadius: 17, bottomTrailingRadius: 17)
			).padding(1)
			
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
		Task {
			if FileManager.default.fileExists(
				atPath: attachment.localUrl.path
			) && downloads.tasks[attachment.url] == nil {
				DispatchQueue.main.async {
					downloads.tasks[attachment.url] = .completed(attachment.localUrl)
				}
			}
		}
	}
}
