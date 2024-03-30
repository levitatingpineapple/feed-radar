import SwiftUI
import AVKit
import UniformTypeIdentifiers
import GRDBQuery

struct AttachmentsView: View {
	let item: Item
	let invalidateSize: () -> Void
	@Query<Attachment.Request> var attachments: Array<Attachment>
	@Environment(\.dynamicTypeSize) var dynamicTypeSize
	
	init(
		item: Item,
		invalidateSize: @escaping () -> Void = { }
	) {
		self.item = item
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
			Text(item.title).font(.title).bold()
			if attachments.isEmpty {
				Divider()
			} else {
				ForEach(attachments) { attachment in
					AttachmentView(
						item: item,
						attachment: attachment,
						invalidateSize: invalidateSize
					)
				}
			}
		}
		.padding(.horizontal, 16)
		.frame(maxWidth: 720 * dynamicTypeSize.scale)
		.onChange(of: attachments) { invalidateSize() }
		.onChange(of: dynamicTypeSize) { invalidateSize() }
	}
}
