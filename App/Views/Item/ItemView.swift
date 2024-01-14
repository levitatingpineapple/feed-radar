import SwiftUI
import GRDBQuery

/// Loads ``ItemView`` lazily
///
/// Technically this shoul not be needed, but SwiftUI seems to call
/// `DynamicProperty.update()` for all list items instantly, not as they are dequed.
struct LazyItemView: View {
	let showsFeed: Bool
	let id: Item.ID
	@State private var showsItem: Bool = false
	
	var body: some View {
		if showsItem {
			ItemView(
				showsFeed: showsFeed,
				item: Query(Item.RequestSingle(id: id), in: \.store)
			)
		} else {
			Color.clear.onAppear { showsItem = true }
		}
	}
}

struct ItemView: View {
	let showsFeed: Bool
	@Environment(Navigation.self) var navigation
	@Environment(\.store) var store: Store
	@Query<Item.RequestSingle> var item: Item?
	
	func tags(item: Item) -> some View {
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
	
	var body: some View {
		if let item {
			ZStack {
				NavigationLink(value: item.id) { EmptyView() }.opacity(.zero)
				VStack(alignment: .leading, spacing: 8) {
					HStack(alignment: .top) {
						VStack(alignment: .leading) {
							if showsFeed { FeedView(source: item.source) }
							Text(item.title).bold()
						}
						Spacer()
						tags(item: item)
					}
					HStack {
						if let author = item.author { Text(author).lineLimit(1) }
						Spacer()
						if let time = item.time {
							if Date.now.timeIntervalSince1970 - time < (60 * 60 * 24 * 8) {
								Text(
									Date(timeIntervalSince1970: time),
									format: .relative(presentation: .named)
								)
							} else {
								Text(
									Date(timeIntervalSince1970: time),
									format: Date.FormatStyle(date: .abbreviated, time: .omitted)
								)
							}
						}
					}.font(.caption).foregroundColor(.secondary)
				}
				.swipeActions(edge: .leading) {
					Button {
						store.toggleRead(for: item)
					} label: {
						Image(systemName: item.isRead ? "circle.fill" : "circle.slash.fill")
					}.tint(.accentColor)
				}
				.swipeActions(edge: .trailing) {
					Button {
						store.toggleStarred(for: item)
					} label: {
						Image(systemName: item.isStarred ? "star.slash.fill" : "star.fill")
					}.tint(.orange)
				}
				.contextMenu(
					ContextMenu {
						if let url = item.url {
							Button {
								UIPasteboard.general.url = url
							} label: { Label("Copy Link", systemImage: "doc.on.doc") }
							Button {
								UIApplication.shared.open(url)
							} label: { Label("Open in Browser", systemImage: "safari") }
							ShareLink(item: url)
						}
						Button(role: .destructive ) {
							try? FileManager.default.removeItem(at: .attachments(itemId: item.id))
						} label: { Label("Remove local attachments", systemImage: "paperclip") }
					}
				)
			}
		}
	}
}
