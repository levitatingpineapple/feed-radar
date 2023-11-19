import SwiftUI

struct ImportView: View {
	@Environment(\.modelContext) private var modelContext
	@State var isPresented = false
	@State var isImporting = false
	@State var input = String()
	@State var test = String()
	
	var body: some View {
		Button {
			isPresented = true
		} label: {
			Label("Add Item", systemImage: "plus")
		}
		.sheet(isPresented: $isPresented) {
			VStack {
				TextField("Feed URLs", text: $input, axis: .vertical)
				Spacer()
				Button("Import") {
					Task { await importFeed(input: input) }
				}.buttonStyle(.borderedProminent)
			}.padding()
				.frame(idealWidth: 800, idealHeight: 600)
		}
	}
	
	@MainActor
	private func importFeed(input: String) async {
		if let url = URL(string: input) {
			isImporting = true
			do {
				let feed = try await Feed(url: url)
				modelContext.insert(feed)
			} catch {
				test = "Could not import: \(error)"
			}
			isImporting = false
		}
	}
}
