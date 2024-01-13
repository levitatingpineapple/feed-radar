import SwiftUI
import GRDBQuery
import Combine

@Observable class Test {
	var count: Int = .zero
	private var bag = Set<AnyCancellable>()
	
	init(filter: Filter) {
		Item.RequestCount(filter: filter)
			.publisher(in: StoreKey.defaultValue)
			.receive(on: DispatchQueue.main)
			.sink(
				receiveCompletion: { _ in },
				receiveValue: { [weak self] value in self?.count = value }
			)
			.store(in: &bag)
	}
}

struct CountView: View {
	@State private var test: Test
	
	init(filter: Filter) {
		self.test = Test(filter: filter)
	}
	
	var body: some View {
		if test.count > .zero {
			Text(String(test.count))
				.contentTransition(.numericText())
				.animation(.default, value: test.count)
				.lineLimit(1)
				.foregroundStyle(Color.white)
				.font(.caption).fontWeight(.heavy)
				.padding(.vertical, 4).padding(.horizontal, 8)
		}
	}
}
