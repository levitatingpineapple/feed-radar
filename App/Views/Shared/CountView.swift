import SwiftUI
import GRDBQuery
import Combine

struct CountView: View {
	@Query<Item.RequestCount> var count: Int
	
	init(filter: Filter) {
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
				.contentTransition(.numericText())
				.animation(.default, value: count)
				.lineLimit(1)
				.foregroundStyle(Color.white)
				.font(.caption).fontWeight(.heavy)
				.padding(.vertical, 4).padding(.horizontal, 8)
		}
	}
}
