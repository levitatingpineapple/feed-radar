import SwiftUI
import GRDBQuery

struct ContentView: View {
	@ObservedObject var store: Store = .shared
	
	
	var body: some View {
		NavigationSplitView(columnVisibility: .constant(.all)) {
			FeedsView()
		} content: {
			if let filter = store.filter {
				ItemsView(filter: filter)
			}
		} detail: {
			
		}
		.task { Store.shared.fetch(.all) }
	}
}
