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
#if os(iOS)
				ScrollView {
					VStack(alignment: .leading, spacing: .zero) {
						if let title = item.title {
							Text(title).font(.largeTitle).bold().padding(.horizontal, 16)
						}
						if let content = item.content {
							HtmlView(body: content).border(.red)
						}
					}
				}
#elseif os(macOS)
				WebView(html: .html(content)).ignoresSafeArea()
#endif
			case .link:
				if let url = item.url {
#if os(iOS)
					SafariWebView(url: url).ignoresSafeArea()
#elseif os(macOS)
					WebView(html: .url(url))
#endif
				} else {
					Spacer()
				}
			}
		}
#if os(iOS)
		.background(Color(uiColor: .systemBackground))
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
