import SwiftUI
import GRDBQuery

struct FilterSettingsView: View {
	@Query(Feed.Request(), in: \.store) private var feeds: Array<Feed>
	@ObservedObject var store: Store = .shared
	@Environment(\.dismiss) var dismiss
	
	
	var body: some View {
		VStack(alignment: .leading, spacing: .zero) {
			HStack {
				Picker("Read", selection: Binding(
					get: { store.filter?.isRead },
					set: { store.filter?.isRead = $0 }
				)) {
					Text("All").tag(Optional<Bool>.none)
					Image(systemName: "circle.fill").tag(Optional<Bool>.some(false))
					Image(systemName: "circle").tint(.accentColor).tag(Optional<Bool>.some(true))
				}.pickerStyle(.segmented)
				
				Picker("Starred", selection: Binding(
					get: { store.filter?.isStarred },
					set: { store.filter?.isStarred = $0 }
				)) {
					Text("All").tag(Optional<Bool>.none)
					Image(systemName: "star.fill").tint(.accentColor).tag(Optional<Bool>.some(true))
					Image(systemName: "star").tag(Optional<Bool>.some(false))
				}.pickerStyle(.segmented).tint(.orange)
			}
			Picker("Feed", selection: Binding(
				get: { store.filter?.feed },
				set: { store.filter?.feed = $0 }
			)) {
				Text("All").tag(Optional<Feed>.none)
				ForEach(feeds, id: \.source) { feed in
					Text(feed.title ?? feed.source.absoluteString)
						.tag(Optional<Feed>.some(feed))
				}
			}.pickerStyle(.inline)
		}
		.padding()
		.background(
			GeometryReader {
				Color.clear.presentationDetents(
					[.height($0.size.height)]
				)
			}
		)
	}
}
