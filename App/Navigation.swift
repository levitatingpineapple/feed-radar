import Combine
import SwiftUI

/// Scene's navigation model
///
/// Handles navigation state for a given scene.
/// The navigation state is persisted in user defaults.
/// Additionally this class is responsible for marking deselected items as read
/// and updating the badge count.
final class Navigation: ObservableObject {
	
	/// Filters items displayed in ``ItemsView``
	/// Various filters can be selected from the sidebar
	/// and further tweaked from ``FilterSettingsView``
	@Published var filter: Filter?
	
	/// Determines content of the ``ItemDetailView``
	@Published var itemId: Item.ID?
	
	private var bag = Set<AnyCancellable>()
	private var store: Store
	
	/// - Parameter store: Used for persisting read items
	init(store: Store) {
		self.store = store
		
		// Persist selected filter
		filter = UserDefaults.standard
			.data(forKey: .filterKey)
			.flatMap { Filter(rawValue: $0) }
		$filter
			.removeDuplicates()
			.sink { UserDefaults.standard.setValue($0?.rawValue, forKey: .filterKey) }
			.store(in: &bag)
		
		// Mark deseledted as read
		$itemId
			.removeDuplicates()
			.scan((Optional<Item.ID>.none, Optional<Item.ID>.none)) { ($0.1, $1) }
			.sink { (deselected, selected) in
				if let deselected { self.store.markAsRead(itemId: deselected) }
			}
			.store(in: &bag)
		
		// Update app icon badge
		Item.RequestCount(filter: Filter(isRead: false))
			.publisher(in: self.store)
			.replaceError(with: .zero)
			.sink { UNUserNotificationCenter.current().setBadgeCount($0) }
			.store(in: &bag)
	}
}
