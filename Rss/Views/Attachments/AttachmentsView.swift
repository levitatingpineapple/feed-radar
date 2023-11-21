import SwiftUI
import AVKit
import UniformTypeIdentifiers
import GRDBQuery

struct AttachmentsView: View {
	let title: String
	let scale: Double
	@Query<Attachment.Request> var attachments: Array<Attachment>
	
	init(title: String, request: Attachment.Request, scale: Double) {
		self.title = title
		self.scale = scale
		_attachments = Query(
			Binding(get: { request }, set: { _ in }),
			in: \.store
		)
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text(title).font(.largeTitle).bold()
			ForEach(attachments) { attachment in
				VStack(spacing: .zero) {
					HStack {
						Text(attachment.title ?? attachment.url.lastPathComponent).lineLimit(1).truncationMode(.head)
						Spacer()
						DownloadView(size: 24, type: attachment.type, url: attachment.url)
					}
					.padding(.horizontal, 16)
					.padding(.vertical, 12)
					MediaView(attachment: attachment)
				}
				.background(Color(.secondarySystemBackground))
				.cornerRadius(16)
			}
			Divider()
		}
		.padding(.horizontal, 16)
		.frame(maxWidth: 720 * scale)
	}
}
