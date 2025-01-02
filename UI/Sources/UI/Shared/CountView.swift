import SwiftUI
import GRDBQuery
import Combine
import Core

struct CountView: View {
	@Query<Request> var count: Int
	
	init(filter: Filter) {
		_count = Query(
			Binding(
				get: { Request(filter: filter) },
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

extension CountView {
	public struct Request: Queryable {
		public static var defaultValue: Int = .zero
		public let filter: Filter
		
		public init(filter: Filter) {
			self.filter = filter
		}
		
		public func publisher(in store: Store) -> AnyPublisher<Int, Error> {
			Item.publisherCount(in: store, filter: filter)
		}
	}
}
