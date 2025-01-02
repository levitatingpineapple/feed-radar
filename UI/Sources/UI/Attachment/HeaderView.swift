import SwiftUI
import AVKit
import UniformTypeIdentifiers
import Combine
import GRDBQuery
import Core

struct HeaderView: View {
	let item: Item
	let invalidateSize: () -> Void
	@Query<Request> var attachments: Array<Attachment>
	@Environment(\.dynamicTypeSize) var dynamicTypeSize
	
	init(
		item: Item,
		invalidateSize: @escaping () -> Void = { }
	) {
		self.item = item
		self.invalidateSize = invalidateSize
		_attachments = Query(
			Binding(
				get: { Request(itemId: item.id) },
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
		.frame(maxWidth: 720 * dynamicTypeSize.scale, alignment: .center)
		.onChange(of: attachments) { invalidateSize() }
		.onChange(of: dynamicTypeSize) { invalidateSize() }
	}
}

extension HeaderView {
	public struct Request: Queryable {
		public static var defaultValue = Array<Attachment>()
		
		public let itemId: Item.ID
		
		public func publisher(in store: Store) -> AnyPublisher<Array<Attachment>, Error> {
			Attachment.publisher(in: store, with: itemId)
		}
	}
}
