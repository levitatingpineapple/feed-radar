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
				// Optimisation: SwiftUI will dismantle views inside `ForEach` on state change
				// Using explicit optional view will just update contained view
				attachmentView(0)
				attachmentView(1)
				attachmentView(2)
				attachmentView(3)
				attachmentView(4)
				attachmentView(5)
				attachmentView(6)
				attachmentView(7)
				if attachments.count > 8 {
		// }
					ForEach(attachments[8...]) {
						AttachmentView(
							item: item,
							attachment: $0,
							invalidateSize: invalidateSize
						).border(.red)
					}
				}
			}
		}
		.padding(.horizontal, 16)
		.frame(maxWidth: 720 * scale)
		.onChange(of: attachments) { invalidateSize() }
		.onChange(of: scale) { invalidateSize() }
	}

	@ViewBuilder
	func attachmentView(_ index: Int) -> some View {
		if attachments.count > index {
			AttachmentView(
				item: item,
				attachment: attachments[index],
				invalidateSize: invalidateSize
			)
		}
	}
}
