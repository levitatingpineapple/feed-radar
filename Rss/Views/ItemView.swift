import SwiftUI

struct ItemView: View {
	@AppStorage var showWeb: Bool
	@AppStorage("scaling") private var scale: Double = 1
	
	let item: Item
	
	init(item: Item) {
		self.item = item
		self._showWeb = .init(wrappedValue: false, item.feedUrl.absoluteString, store: .standard)
	}
	
	var body: some View {
		VStack(spacing: .zero) {
			if showWeb, let url = item.url {
				SafariViewController (url: url).ignoresSafeArea()
			} else {
				WebViewController(
					content: item.content ?? "NO CONTENT",
					title: item.title ?? "NO TITLE", 
					request: Attachment.Request(feedUrl: item.feedUrl, itemId: item.itemId),
					scale: $scale
				)
			}
		}
		.background(Color(uiColor: .systemBackground))
		.toolbar {
			if !showWeb {
				toolbarItem(image: "plus") { scale += 0.1 }
				toolbarItem(image: "minus") { scale -= 0.1 }
			}
			toolbarItem(image: showWeb ?  "doc.plaintext" : "globe") { showWeb.toggle() }
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
