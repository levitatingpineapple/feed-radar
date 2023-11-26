import SwiftUI

struct FilterView: View {
	let filter: Item.Filter
	var isCompact: Bool = false
	
	var body: some View {
		HStack {
			switch filter {
			case .unread:
				HStack {
					Image(systemName: "tray.fill")
						.resizable()
						.scaledToFit()
						.frame(maxWidth: 28, maxHeight: 28)
						.foregroundColor(.accentColor)
					Text("Unread")
				}
			case .starred:
				HStack {
					Image(systemName: "star.fill")
						.resizable()
						.scaledToFit()
						.frame(maxWidth: 28, maxHeight: 28)
						.foregroundColor(.orange)
					Text("Starred")
				}
			case let .feed(feed):
				HStack {
					FeedView(url: feed.url)
				}
			}
			if !isCompact { Spacer() }
			CountView(filter: filter)
		}

	}
}
