import SwiftUI
import GRDBQuery

struct ContentView: View {
	@State private var filter: Filter?
	@State private var item: Item?
	
	var body: some View {
		NavigationSplitView(columnVisibility: .constant(.all)) {
			FeedsView(filter: $filter)
		} content: {
			if let filter {
				ItemsView(
					request: Item.Request(filter: filter),
					item: $item
				)
			}
		} detail: {
			if let item = item {
				ItemView(item: item)
			}
		}
		.task { Store.shared.fetch(.all) }
	}
}
