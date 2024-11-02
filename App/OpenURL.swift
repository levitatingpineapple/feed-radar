import SwiftUI

struct OpenURL: ViewModifier {
	@Environment(\.store) private var store: Store
	@State private var feedUrl: URL?
	
	func body(content: Content) -> some View {
		content.onOpenURL {
			feedUrl = URL(string: $0.absoluteString.strippingPrefix("feed:"))
		}
		.alert(
			"Import Feed?\n" + (feedUrl?.absoluteString ?? String()),
			isPresented: Binding(
				get: { feedUrl != nil },
				set: { if !$0 { feedUrl = nil } }
			)
		) {
			Button("Import") {
				if let source = feedUrl {
					Task { await store.add(feed: Feed(source: source)) }
					feedUrl = nil
				}
			}
		}
	}
}
