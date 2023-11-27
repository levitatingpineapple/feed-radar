import SwiftUI

struct ItemDetailView: View {
	@AppStorage var showWeb: Bool
	@AppStorage("scaling") private var scale: Double = 1
	@Environment(\.colorScheme) var colorScheme
	
	@State private var showsPopover: Bool = false
	
	let item: Item
	
	init(item: Item) {
		self.item = item
		self._showWeb = .init(wrappedValue: false, item.source.absoluteString, store: .standard)
	}
	
	var body: some View {
		VStack(spacing: .zero) {
			if showWeb, let url = item.url {
				SafariViewController (url: url).ignoresSafeArea()
			} else {
				WebViewController(
					content: item.content ?? String(),
					title: item.title ?? item.itemId,
					request: Attachment.Request(source: item.source, itemId: item.itemId),
					scale: $scale
				).ignoresSafeArea(edges: [.bottom, .horizontal])
			}
		}
		.background(
			colorScheme == .dark ? .black : .white
		)
		
		.toolbar {
			if let url = item.url {
				toolbarItem(image: "safari") { UIApplication.shared.open(url) }
			}
		}
	}
	
	private func toolbarItem(
		image: String,
		action: @escaping () -> Void
	) ->  ToolbarItem<Void, some View> {
		ToolbarItem {
			Button(action: action) {
				Image(systemName: image)
			}
		}
	}
}
