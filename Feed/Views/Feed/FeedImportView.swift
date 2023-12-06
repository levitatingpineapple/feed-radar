import SwiftUI

struct FeedImportView: View {
	@State var isPresented = false
	@State var input = String()
	@State var sources = Array<URL>()
	
	@Environment(\.dismiss) var dismiss
	
	func add(source: URL) {
		let feed = Feed(source: source)
		Store.shared.add(feed: feed)
		sources.removeAll { $0 == source }
	}
	
	var body: some View {
		Group {
			if sources.isEmpty {
				VStack {
					TextEditor(text: $input).cornerRadius(4)
					Spacer()
					Button("Extract Feed Links") {
						sources = input
							.matches(of: #/(https?://[a-zA-Z0-9;,./?:@&=+$\-_.!]*)/#)
							.compactMap { match in URL(string: String(match.output.1)) }
					}.buttonStyle(.borderedProminent)
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
