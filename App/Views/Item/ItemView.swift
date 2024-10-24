import SwiftUI
import GRDBQuery

struct ItemView: View {
	let showsFeed: Bool
	@Query<Item.RequestRedacted> var item: Item?

	init(id: Item.ID, showsFeed: Bool) {
		self.showsFeed = showsFeed
		_item = Query(
			Binding(
				get: { Item.RequestRedacted(id: id) },
				set: { _ in }
			),
			in: \.store
		)
	}

	var body: some View {
		if let item { _ItemView(showsFeed: showsFeed, item: item) }
	}

	private struct _ItemView: View {
		@Environment(\.store) var store: Store
		let showsFeed: Bool
		let item: Item

		var body: some View {
			VStack(alignment: .leading, spacing: 8) {
				HStack(alignment: .top) {
					VStack(alignment: .leading) {
						if showsFeed { FeedView(source: item.source) }
						Text(item.title).bold()
					}
					Spacer()
					tags
				}
				HStack {
					if let author = item.author { Text(author).lineLimit(1) }
					Spacer()
					if let time = item.time { formatted(time) }
				}
				.font(.caption)
				.foregroundColor(.secondary)
			}
			.swipeActions(edge: .leading) { leadingSwipe }
			.swipeActions(edge: .trailing) { trailingSwipe }
			.contextMenu { menu }
		}

		@ViewBuilder
		private func formatted(_ timeInterval: TimeInterval) -> some View {
			if Date.now.timeIntervalSince1970 - timeInterval < (60 * 60 * 24 * 8) {
				Text(
					Date(timeIntervalSince1970: timeInterval),
					format: .relative(presentation: .named)
				)
			} else {
				Text(
					Date(timeIntervalSince1970: timeInterval),
					format: Date.FormatStyle(date: .abbreviated, time: .omitted)
				)
			}
		}

		@ViewBuilder
		private var leadingSwipe: some View {
			Button {
				store.toggleRead(for: item)
			} label: {
				Image(systemName: item.isRead ? "circle.fill" : "circle.slash.fill")
			}
			.tint(.accentColor)
		}

		@ViewBuilder
		private var trailingSwipe: some View {
			Button {
				store.toggleStarred(for: item)
			} label: {
				Image(systemName: item.isStarred ? "star.slash.fill" : "star.fill")
			}
			.tint(.orange)
		}

		@ViewBuilder
		private var menu: some View {
			if let url = item.url {
				Button {
					UIPasteboard.general.url = url
				} label: {
					Label("Copy Link", systemImage: "doc.on.doc")
				}
				Button {
					UIApplication.shared.open(url)
				} label: {
					Label("Open in Browser", systemImage: "safari")
				}
				ShareLink(item: url)
			}
			Button(role: .destructive ) {
				try? FileManager.default.removeItem(at: .attachments(itemId: item.id))
			} label: {
				Label("Remove local attachments", systemImage: "paperclip")
			}
		}

		@ViewBuilder
		private var tags: some View {
			ZStack(alignment: .trailing) {
				Color.clear.frame(width: 30, height: 14)
				HStack(spacing: 4) {
					if item.isStarred {
						Image(systemName: "star.fill").resizable().scaledToFit()
							.frame(width: 14, height: 14)
							.foregroundColor(.orange)
					}
					if !item.isRead {
						Image(systemName: "circle.fill").resizable().scaledToFit()
							.frame(width: 12, height: 12)
							.foregroundColor(.accentColor)
					}
				}
			}
		}
	}
}
