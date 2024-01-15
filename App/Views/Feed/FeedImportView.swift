import SwiftUI

struct FeedImportView: View {
	@State var isPresented = false
	@State var input = String()
	@State var sources = Array<URL>()
	@Environment(\.store) var store: Store
	@Environment(\.dismiss) var dismiss
	
	func add(source: URL) {
		let feed = Feed(source: source)
		Task { await store.add(feed: feed) }
		sources.removeAll { $0 == source }
	}
	
	var body: some View {
		Group {
			if sources.isEmpty {
				VStack(spacing: 16) {
					Text("Add Feeds").font(.largeTitle).frame(alignment: .leading)
					Text("Paste some text that indludes links to feeds. The links must start with ") +
					Text("http:// ").foregroundStyle(Color.accentColor).bold() +
					Text("or ") +
					Text("https:// ").foregroundStyle(Color.accentColor).bold() +
					Text("and be direct links to a feed, as the app does not yet support feed finding")
					TextEditor(text: $input).cornerRadius(4).border(Color.accentColor)
					Spacer()
					Button("Extract Feed Links") {
						sources = input
							.matches(of: #/(https?://[a-zA-Z0-9;,./?:@&=+$\-_.!]*)/#)
							.compactMap { match in URL(string: String(match.output.1)) }
					}
					.buttonStyle(.borderedProminent)
				}.padding()
			} else {
				VStack {
					ScrollView {
						VStack {
							ForEach(sources, id: \.self) { source in
								HStack {
									SystemImageButton(systemName: "plus") { add(source: source) }
									Text(source.absoluteString).lineLimit(1).truncationMode(.middle)
									Spacer()
								}
							}
						}.padding()
					}
					Button("Import All") {
						sources.forEach { add(source: $0) }
						dismiss()
					}.buttonStyle(.borderedProminent).padding()
				}
			}
		}
		.frame(idealWidth: 540, idealHeight: 800)
		.onChange(of: isPresented) { sources = Array<URL>() }
	}
}
