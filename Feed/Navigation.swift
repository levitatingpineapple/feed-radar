import Combine
import SwiftUI

final class Navigation: ObservableObject {
	@Published var filter: Filter?
	@Published var itemId: Item.ID?
	private var bag = Set<AnyCancellable>()
	private var store: Store
	
	init(store: Store) {
		self.store = store
		
		// Persist filter selection
		filter = UserDefaults.standard
			.data(forKey: .filterKey)
			.flatMap { Filter(rawValue: $0) }
		$filter
			.removeDuplicates()
			.sink { UserDefaults.standard.setValue($0?.rawValue, forKey: .filterKey) }
			.store(in: &bag)
		
		// Mark items as read as they are deselected
		$itemId
			.removeDuplicates()
			.scan((Optional<Item.ID>.none, Optional<Item.ID>.none)) { ($0.1, $1) }
			.sink { (deselected, selected) in
				if let deselected { self.store.markAsRead(id: deselected) }
			}
			.store(in: &bag)
		
		// Update unread badge
		Item.RequestCount(filter: Filter(isRead: false))
			.publisher(in: self.store)
			.replaceError(with: .zero)
			.sink { UNUserNotificationCenter.current().setBadgeCount($0) }
			.store(in: &bag)
	}
}
