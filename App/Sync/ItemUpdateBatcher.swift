import Foundation
import Combine

/// Batches writes to the database therefore reducing UI updates.
/// Useful, if device has many updates to apply
class ItemUpdateBatcher {
	private let subject = PassthroughSubject<Item, Never>()
	private var bag = Set<AnyCancellable>()

	init(store: Store) {
		subject
			.collect(.byTimeOrCount(DispatchQueue.main, .seconds(0.25), 128))
			.sink { [weak store] in store?.update(items: $0) }
			.store(in: &bag)
	}
	
	func update(item: Item) { subject.send(item) }
}
