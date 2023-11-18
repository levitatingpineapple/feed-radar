import SwiftUI

struct ItemView: View {
	enum Display {
		case html
		case link
	}
	
	@State private var display: Display = .html
	
	let item: Item
	
	var body: some View {
		VStack(spacing: .zero) {
			switch display {
			case .html:
				if let title = item.title {
					Text(title).font(.title).padding(16)
				}
				if let html = item.content {
					WebView(html: .html(html)).ignoresSafeArea()
				}
			case .link:
				if let url = item.url {
#if os(iOS)
					SafariWebView(url: url).ignoresSafeArea()
#elseif os(macOS)
					WebView(html: .url(url)).ignoresSafeArea()
#endif
				} else {
					Spacer()
				}
			}
		}
#if os(iOS)
		.background(Color(.systemBackground))
#elseif os(macOS)
		.background(Color(.textBackgroundColor))
#endif
		.toolbar {
			ToolbarItem {
				Button {
					display = switch display {
					case .html: .link
					case .link: .html
					}
				} label: {
					Image(systemName: "eye")
				}
			}
		}
	}
}
