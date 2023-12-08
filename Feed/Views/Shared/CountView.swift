import SwiftUI
import GRDBQuery

struct CountView: View {
	@Query<Item.RequestCount> var count: Int
	
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
