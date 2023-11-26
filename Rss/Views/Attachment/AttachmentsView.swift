import SwiftUI
import AVKit
import UniformTypeIdentifiers
import GRDBQuery

struct AttachmentsView: View {
	let title: String
	let scale: Double
	@Query<Attachment.Request> var attachments: Array<Attachment>
	@State private var selected: Int = .zero
	
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
			HStack {
				if attachments.count > 1 {
					Button {
						selected = max(0, selected - 1)
					} label: {
						Image(systemName: "chevron.compact.left").resizable().scaledToFit()
							.frame(width: 24, height: 48)
					}.disabled(selected <= .zero)
				}
				if !attachments.isEmpty {
					AttachmentView(attachment: attachments[min(selected, attachments.count - 1)])
				}
				if attachments.count > 1 {
					Button {
						selected = min(attachments.count - 1, selected + 1)
					} label: {
						Image(systemName: "chevron.compact.right").resizable().scaledToFit()
							.frame(width: 24, height: 48)
					}.disabled(selected >= attachments.count - 1)
				}
			}
			Divider()
		}
		.padding(.horizontal, 16)
		.frame(maxWidth: 720 * scale)
		.onChange(of: attachments) { selected = .zero }
	}
}
