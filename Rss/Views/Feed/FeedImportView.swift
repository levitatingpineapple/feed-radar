import SwiftUI

struct FeedImportView: View {
	@State var isPresented = false
	@State var isImporting = false
	@State var input = String()
	@State var test = String()
	
	var body: some View {
		SystemImageButton(
			systemName: "plus"
		) { isPresented = true }
		.popover(isPresented: $isPresented) {
			VStack {
				TextField("Feed URLs", text: $input, axis: .vertical)
				Spacer()
				Button("Import") {
					if let source = URL(string: input) {
						Store.shared.add(feed: Feed(source: source))
					}
				}.buttonStyle(.borderedProminent)
			}.padding().frame(idealWidth: 400, idealHeight: 600)
		}
	}
}
