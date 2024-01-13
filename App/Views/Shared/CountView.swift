import SwiftUI
import GRDBQuery
import Combine

struct CountView: View {
	@State private var model: Model
	
	init(filter: Filter) {
		self.model = Model(filter: filter)
	}
	
	var body: some View {
		if model.count > .zero {
			Text(String(model.count))
				.contentTransition(.numericText())
				.animation(.default, value: model.count)
				.lineLimit(1)
				.foregroundStyle(Color.white)
				.font(.caption).fontWeight(.heavy)
				.padding(.vertical, 4).padding(.horizontal, 8)
		}
	}
}

extension CountView {
	@Observable class Model {
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
}
