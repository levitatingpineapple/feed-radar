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
			case .link:
				if let url = item.url {
					SafariWebView(url: url).ignoresSafeArea()
				} else {
					Spacer()
				}
			}
		}
		.background(Color(uiColor: .systemBackground))
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
