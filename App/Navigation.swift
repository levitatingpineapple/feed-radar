import Combine
import SwiftUI

/// Scene's navigation model
///
/// Handles navigation state for a given scene.
/// The navigation state is persisted in user defaults.
/// Additionally this class is responsible for marking deselected items as read
/// and updating the badge count.
@MainActor
@Observable
final class Navigation {
	/// Filters items displayed in ``ItemListView``
	/// Various filters can be selected from the sidebar
	/// and further tweaked from ``FilterSettingsView``
	var filter: Filter? {
		didSet {
			UserDefaults.standard.setValue(
				filter?.rawValue,
				forKey: .filterKey
			)
			itemId = nil // Changing filter deselects item
		}
	}
	
	/// Determines content of the ``ItemDetailView``
	var itemId: Item.ID? {
		didSet {
			if let deselected {
				store.markAsRead(itemId: deselected)
			}
			deselected = itemId
		}
	}

	private var deselected: Item.ID?
	
	private var bag = Set<AnyCancellable>()
	private var store: Store
	
	/// - Parameter store: Used for persisting read items
	init(store: Store) {
		self.store = store
		
		filter = UserDefaults.standard
			.data(forKey: .filterKey)
			.flatMap { Filter(rawValue: $0) }
		Item.RequestCount(filter: Filter(isRead: false))
			.publisher(in: self.store)
			.replaceError(with: .zero)
			.sink { UNUserNotificationCenter.current().setBadgeCount($0) }
			.store(in: &bag)
	}
}
