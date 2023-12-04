import SwiftUI

struct ItemDetailView: View {
	let item: Item
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.self) var environmentValues
	@AppStorage var display: Feed.Display
	@AppStorage(.contentScaleKey) private var scale: Double = 1
	
	init(item: Item) {
		self.item = item
		self._display = AppStorage(
			wrappedValue: Feed.Display(mode: .item, opensReader: false, isInverted: false),
			.displayKey(source: item.source)
		)
	}
	
	var displayView: some View {
		HStack {
			switch display.mode {
			case .item:
				SystemImageButton(systemName: "plus.magnifyingglass") { scale += 0.1 }
				SystemImageButton(systemName: "minus.magnifyingglass") { scale -= 0.1 }
			case .link:
				if ProcessInfo.processInfo.isiOSAppOnMac {
					SystemImageButton(
						systemName: display.isInverted ? "circle.lefthalf.filled" : "circle.righthalf.filled"
					) { display.isInverted.toggle() }
				} else {
					SystemImageButton(
						systemName: display.opensReader ? "doc.plaintext.fill" : "doc.plaintext"
					) { display.opensReader.toggle() }
				}
			}
			Picker("Select Display", selection: $display.mode) {
				Image(systemName: "text.justify.leading")
					.tag(Feed.Display.Mode.item)
				Image(systemName: "globe")
					.tag(Feed.Display.Mode.link)
			}.pickerStyle(.segmented).frame(maxWidth: 64)
		}
	}
	
	var body: some View {
		VStack(spacing: .zero) {
			switch display.mode {
			case .item:
				if let content = item.content {
					WebViewController(
						htmlString: Html(
							scale: scale,
							style: .style,
							body: content,
							environmentValues: environmentValues
						).string,
						title: item.title ?? item.itemId,
						base: (item.url ?? item.source).base,
						request: Attachment.Request(source: item.source, itemId: item.itemId),
						scale: $scale
					).ignoresSafeArea()
				}
			case .link:
				if let url = item.url {
					if display.isInverted {
						SafariViewController(url: url, reader: display.opensReader)
							.ignoresSafeArea()
							.colorInvert()
							.hueRotation(.degrees(180))
					} else {
						SafariViewController(url: url, reader: display.opensReader)
							.ignoresSafeArea()
					}
					
				}
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
