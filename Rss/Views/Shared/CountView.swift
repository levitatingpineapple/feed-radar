import SwiftUI
import GRDBQuery

struct CountView: View {
	@Query<Item.RequestCount> var count: Int
	
	init(filter: Item.Filter) {
		_count = Query(
			Binding(
				get: { Item.RequestCount(filter: filter) },
				set: { _ in }
			),
			in: \.store
		)
	}
	
	var body: some View {
		if count > .zero {
			Text(String(count))
				.foregroundStyle(Color.white)
				.font(.caption).bold()
				.padding(.vertical, 4).padding(.horizontal, 8)
				.background(Color.accentColor)
				.clipShape(Capsule())
		}
	}
}
