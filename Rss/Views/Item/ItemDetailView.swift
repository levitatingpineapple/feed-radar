import SwiftUI

enum Display: Int {
	case content
	case extractedContent
	case webView
}

struct ItemDetailView: View {
	let item: Item
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.self) var environmentValues
	@AppStorage var display: Display
	@AppStorage(.contentScaleKey) private var scale: Double = 1
	
	init(item: Item) {
		self.item = item
		self._display = AppStorage(
			wrappedValue: .content,
			.displayKey(source: item.source)
		)
	}
	
	var displayView: some View {
		HStack {
			if display != .webView {
				SystemImageButton(systemName: "plus.magnifyingglass") { scale += 0.1 }
				SystemImageButton(systemName: "minus.magnifyingglass") { scale -= 0.1 }
			}
			Picker("Select Display", selection: $display) {
				Image(systemName: "text.justify.leading").tag(Display.content)
				Image(systemName: "doc.plaintext").tag(Display.extractedContent)
				Image(systemName: "globe").tag(Display.webView)
			}.pickerStyle(.segmented).frame(width: 108)
		}
	}
	
	func contentView(body: String) -> some View {
		WebViewController(
			htmlString: Html(
				scale: scale,
				style: .style,
				body: body,
				environmentValues: environmentValues
			).string,
			title: item.title ?? item.itemId,
			base: (item.url ?? item.source).base,
			request: Attachment.Request(source: item.source, itemId: item.itemId),
			scale: $scale
		).ignoresSafeArea()
	}
	
	var body: some View {
		VStack(spacing: .zero) {
			switch display {
			case .content:
				if let content = item.content { contentView(body: content) }
			case .extractedContent:
				if let url = item.url {
					if let extracted = item.extracted {
						contentView(body: extracted)
					} else {
						HStack(spacing: 8) {
							ProgressView()
							Text("Extracting")
						}.onAppear {
							Task {
								if let extracted = try? await ContentExtractor().extract(from: url) {
									var item = item
									item.extracted = extracted
									Store.shared.update(item: item)
								}
							}
						}
					}
				}
			case .webView:
				if let url = item.url { SafariViewController(url: url).ignoresSafeArea() }
			}
		}
		.toolbarBackground(Material.bar, for: .navigationBar)
		.toolbar {
			ToolbarItem { displayView }
		}
	}
}

struct SystemImageButton: View {
	let systemName: String
	let action: () -> Void
	
	var body: some View {
		Image(systemName: systemName).resizable()
			.foregroundColor(.accentColor)
			.boxed(padded: true)
			.onTapGesture(perform: action)
	}
}
