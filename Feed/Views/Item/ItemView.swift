import SwiftUI

struct ItemView: View {
	@ObservedObject var store: Store = .shared
	
	let item: Item
	let showsFeed: Bool
	
	var tags: some View {
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
		ZStack {
			NavigationLink(value: item) { EmptyView() }.opacity(.zero)
			VStack(alignment: .leading, spacing: 8) {
				HStack(alignment: .top) {
					VStack(alignment: .leading) {
						if showsFeed { FeedView(source: item.source) }
						Text(item.title ?? item.itemId).bold()
					}
					Spacer()
					tags
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
					Store.shared.toggleRead(for: item)
				} label: {
					Image(systemName: item.isRead ? "circle.fill" : "circle.slash.fill")
				}.tint(.accentColor)
			}
			.swipeActions(edge: .trailing) {
				Button {
					Store.shared.toggleStarred(for: item)
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
						Store.shared.removeAttachments(source: item.source, itemId: item.itemId)
					} label: { Label("Remove attachments", systemImage: "paperclip") }
				}
			)
		}
	}
}
