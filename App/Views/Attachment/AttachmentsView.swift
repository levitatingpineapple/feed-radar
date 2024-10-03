import SwiftUI
import AVKit
import UniformTypeIdentifiers
import GRDBQuery

struct AttachmentsView: View {
	let item: Item
	@Query<Attachment.Request> var attachments: Array<Attachment>
	@Environment(\.dynamicTypeSize) var dynamicTypeSize
	
	init(item: Item) {
		self.item = item
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
						attachment: attachment
					)
				}
			}
		}
		.padding(.horizontal, 16)
		.frame(maxWidth: 720 * dynamicTypeSize.scale)
	}
}
