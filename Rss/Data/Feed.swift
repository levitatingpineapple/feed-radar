import Foundation
import SwiftData

@Model
final class Feed: ObservableObject {
	@Attribute(.unique)
	let id: String
	let url: URL
	let title: String?
	let icon: Data?
	@Relationship(deleteRule: .cascade, inverse: \Item.feed)
	var items = Array<Item>()
	
	@Transient
	@Published var isFetching: Bool = false
	
	init(
		url: URL,
		title: String?,
		id: String,
		icon: Data?,
		items: Array<Item>
	) {
		self.url = url
		self.title = title
		self.id = id
		self.icon = icon
		self.items = items
	}
}
