import SwiftUI
import Combine
import GRDBQuery
import Core

struct FilterSettingsView: View {
	@Query(Request(), in: \.store) private var feeds: Array<Feed>
	@Environment(\.store) var store: Store
	@Environment(\.dismiss) var dismiss
	@Environment(Navigation.self) var navigation
	
	var body: some View {
		VStack(alignment: .leading, spacing: .zero) {
			HStack {
				Picker("Read", selection: Binding(
					get: { navigation.filter?.isRead },
					set: { navigation.filter?.isRead = $0 }
				)) {
					Text("All").tag(Optional<Bool>.none)
					Image(systemName: "circle.fill").tag(Optional<Bool>.some(false))
					Image(systemName: "circle").tint(.accentColor).tag(Optional<Bool>.some(true))
				}.pickerStyle(.segmented)
				Picker("Starred", selection: Binding(
					get: { navigation.filter?.isStarred },
					set: { navigation.filter?.isStarred = $0 }
				)) {
					Text("All").tag(Optional<Bool>.none)
					Image(systemName: "star.fill").tint(.accentColor).tag(Optional<Bool>.some(true))
					Image(systemName: "star").tag(Optional<Bool>.some(false))
				}.pickerStyle(.segmented).tint(.orange)
			}
			Picker("Feed", selection: Binding(
				get: { navigation.filter?.feed },
				set: { navigation.filter?.feed = $0 }
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
			GeometryReader { proxy in
				Color.clear.presentationDetents(
					[.height(proxy.size.height)]
				)
			}
		)
	}
}

extension FilterSettingsView {
	struct Request: Queryable {
		static var defaultValue = Array<Feed>()
		
		func publisher(in store: Store) -> AnyPublisher<Array<Feed>, Error> {
			Feed.publisherAll(in: store)
		}
	}
}
