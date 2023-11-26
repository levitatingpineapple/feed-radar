import SwiftUI

struct FeedImportView: View {
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
		.popover(isPresented: $isPresented) {
			VStack {
				TextField("Feed URLs", text: $input, axis: .vertical)
				Spacer()
				Button("Import") {
					if let url = URL(string: input) {
						Store.shared.fetch(feedUrl: url)
					}
				}.buttonStyle(.borderedProminent)
			}.padding().frame(idealWidth: 400, idealHeight: 600)
		}
	}
}
