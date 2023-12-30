import SwiftUI

struct AttachmentView<Selector: View>: View {
	let attachment: Attachment
	let invalidateSize: () -> Void
	@State private var aspectRatio: Double = 16 / 9
	@Environment(\.store) var store: Store
	@EnvironmentObject var navigation: Navigation
	@ViewBuilder var selector: () -> Selector
	
	var url: URL {
		if case let .completed(url) = Attachments.shared.tasks[attachment.url] {
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
								.onAppear { invalidateSize() }
						default:
							EmptyView()
						}
					}
				} else if attachment.type.conforms(to: .audiovisualContent) {
					VStack {
						PlayerViewController(
							url: url,
							item: navigation.itemId.flatMap { store.item(id: $0) },
							aspectRatio: $aspectRatio
						)
						.aspectRatio(aspectRatio, contentMode: .fit)
						.onChange(of: aspectRatio) { invalidateSize() }
					}
					
				}
			}.clipShape(
				UnevenRoundedRectangle(bottomLeadingRadius: 17, bottomTrailingRadius: 17)
			).padding(1)
			
		}
		.background(Color(.secondarySystemBackground))
		.cornerRadius(16)
		.onAppear { Attachments.shared.load(local: attachment) }
		.onChange(of: attachment) {
			aspectRatio = 16 / 9
			Attachments.shared.load(local: attachment)
		}
	}
	
//	private func checkLocalFile() {
//		Task {
//			if FileManager.default.fileExists(
//				atPath: attachment.localUrl.path
//			) && attachments.tasks[attachment.url] == nil {
//				DispatchQueue.main.async {
//					attachments.tasks[attachment.url] = .completed(attachment.localUrl)
//				}
//			}
//		}
//	}
}
