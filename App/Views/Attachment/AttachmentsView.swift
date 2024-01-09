import SwiftUI
import AVKit
import UniformTypeIdentifiers
import GRDBQuery

struct AttachmentsView: View {
	let title: String
	let scale: Double
	let invalidateSize: () -> Void
	@Query<Attachment.Request> var attachments: Array<Attachment>
	
	init(
		title: String,
		request: Attachment.Request,
		scale: Double,
		invalidateSize: @escaping () -> Void = { }
	) {
		self.title = title
		self.scale = scale
		self.invalidateSize = invalidateSize
		_attachments = Query(
			Binding(get: { request }, set: { _ in }),
			in: \.store
		)
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text(title).font(.largeTitle).bold()
			if attachments.isEmpty {
				Divider()
			} else {
				ForEach(attachments) {
					AttachmentView(attachment: $0, invalidateSize: invalidateSize)
				}
			}
		}
		.padding(.horizontal, 16)
		.frame(maxWidth: 720 * scale)
		.onChange(of: attachments) { invalidateSize() }
		.onChange(of: scale) { invalidateSize() }
	}
}
