import SwiftUI
import GRDBQuery

struct ItemDetailView: View {
	let item: Item
	@Environment(\.store) var store: Store
	@Environment(\.colorScheme) var colorScheme
	@AppStorage var display: Display
	
	init(item: Item) {
		self.item = item
		self._display = AppStorage(
			wrappedValue: .content,
			.displayKey(source: item.source)
		)
	}
	
	var displayView: some View {
		HStack {
			Picker("Select Display", selection: $display) {
				Image(systemName: "text.justify.leading").tag(Display.content)
				Image(systemName: "doc.plaintext").tag(Display.extractedContent)
				Image(systemName: "globe").tag(Display.webView)
			}.pickerStyle(.segmented).frame(width: 108)
			SystemImageButton(
				systemName: item.isStarred ? "star.fill" : "star",
				color: .orange
			) { store.toggleStarred(for: item) }
		}
	}
	
	func contentView(_ body: String) -> some View {
		HeaderWebView(
			extracted: display == .extractedContent,
			item: item
		)
		.ignoresSafeArea()
	}
	
	var body: some View {
		VStack(spacing: .zero) {
			switch display {
			case .content:
				contentView(item.content ?? String())
			case .extractedContent:
				if let extracted = item.extracted {
					contentView(extracted)
				} else {
					HStack(spacing: 8) {
						ProgressView()
						Text("Extracting")
					}.onAppear {
						Task { try? await ContentExtractor.shared.extract(item: item, into: store) }
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
		.onChange(of: item) {
			if display == .extractedContent {
				Task { try? await ContentExtractor.shared.extract(item: item, into: store) }
			}
		}
	}
}

struct SystemImageButton: View {
	let systemName: String
	var color: Color? = nil
	let action: () -> Void
	
	var body: some View {
		Image(systemName: systemName).resizable()
			.foregroundColor(color)
			.boxed(padded: true)
			.onTapGesture(perform: action)
	}
}

/// ``ItemDetailView`` wrapper that handles empty state
struct ItemDetailWrapperView: View {
	@Query<Item.RequestSingle> var item: Item?
	
	init(id: Item.ID) {
		_item = Query(
			Binding(
				get: { Item.RequestSingle(id: id) },
				set: { _ in }
			),
			in: \.store
		)
	}
	
	var body: some View {
		if let item { ItemDetailView(item: item) }
	}
}

extension ItemDetailView {
	enum Display: Int {
		case content
		case extractedContent
		case webView
	}
}
