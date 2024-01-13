import SwiftUI
import AVKit
import UniformTypeIdentifiers
import GRDBQuery

struct AttachmentsView: View {
	let item: Item
	let scale: Double
	let invalidateSize: () -> Void
	@Query<Attachment.Request> var attachments: Array<Attachment>
	
	init(
		item: Item,
		scale: Double,
		invalidateSize: @escaping () -> Void = { }
	) {
		self.item = item
		self.scale = scale
		self.invalidateSize = invalidateSize
		_attachments = Query(
			Binding(
				get: { Attachment.Request(itemId: item.id) },
				set: { _ in }
			),
			in: \.store
		)
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text(item.title).font(.largeTitle).bold()
			if attachments.isEmpty {
				Divider()
			} else {
				ForEach(attachments) {
					AttachmentView(
						item: item,
						attachment: $0,
						invalidateSize: invalidateSize
					)
				}
			}
		}
		.padding(.horizontal, 16)
		.frame(maxWidth: 720 * scale)
		.onChange(of: attachments) { invalidateSize() }
		.onChange(of: scale) { invalidateSize() }
	}
}
