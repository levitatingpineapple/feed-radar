import Combine
import SwiftUI

/// Scene's navigation model
///
/// Handles navigation state for a given scene.
/// The navigation state is persisted in user defaults.
/// Additionally this class is responsible for marking deselected items as read
/// and updating the badge count.
@Observable
final class Navigation {
	
	/// Filters items displayed in ``ItemListView``
	/// Various filters can be selected from the sidebar
	/// and further tweaked from ``FilterSettingsView``
	var filter: Filter?
	
	/// Determines content of the ``ItemDetailView``
	var itemId: Item.ID?

	private var deselected: Item.ID?
	
	private var bag = Set<AnyCancellable>()
	private var store: Store
	
	/// - Parameter store: Used for persisting read items
	init(store: Store) {
		self.store = store
		persistFilter()
		filter = UserDefaults.standard
			.data(forKey: .filterKey)
			.flatMap { Filter(rawValue: $0) }
		markDeselectedAsRead()
		
		Item.RequestCount(filter: Filter(isRead: false))
			.publisher(in: self.store)
			.replaceError(with: .zero)
			.sink { UNUserNotificationCenter.current().setBadgeCount($0) }
			.store(in: &bag)
	}
	
	private func persistFilter() {
		_ = withObservationTracking { filter } onChange: { [weak self] in
			UserDefaults.standard.setValue(
				self?.filter?.rawValue,
				forKey: .filterKey
			)
			self?.itemId = nil // Changing filter deselects item
			self?.persistFilter()
		}
	}
	
	private func markDeselectedAsRead() {
		_ = withObservationTracking { itemId } onChange: { [weak self] in
			if let deselected = self?.deselected {
				self?.store.markAsRead(itemId: deselected)
			}
			self?.deselected = self?.itemId
			self?.markDeselectedAsRead()
		}
	}

}

extension Navigation {
	/// Path used by the navigation stack in compact mode
	/// Expected format is ``Filter``, ``Item.ID``
	var path: NavigationPath {
		get {
			var path = NavigationPath()
			if let filter {
				path.append(filter)
				if let itemId {
					path.append(itemId)
				}
			}
			return path
		}
		set {
			let encoder = JSONEncoder()
			let decoder = JSONDecoder()
			if let decoded = try? decoder.decode(
				Array<String>.self,
				from: try! encoder.encode(newValue.codable)
			) {
				switch decoded.count {
					case 0:
						filter = nil
					case 2:
						filter = try? decoder.decode(
							Filter.self,
							from: decoded[1].data(using: .utf8)!
						)
					case 4:
						filter = try? decoder.decode(
							Filter.self,
							from: decoded[3].data(using: .utf8)!
						)
						itemId = try? decoder.decode(
							Item.ID.self,
							from: decoded[1].data(using: .utf8)!
						)
					default:
						fatalError("Unexpected path length")
				}
			}
		}
	}	
}
