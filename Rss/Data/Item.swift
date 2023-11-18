import Foundation
import SwiftData

@Model
final class Item {
	@Attribute(.unique)
	let id: String
	let date: Date?
	let title: String?
	let author: String?
	let content: String?
	let url: URL?
	var feed: Feed? // Managed by SwiftData
	
	init(
		id: String,
		date: Date?,
		title: String?,
		author: String?,
		content: String?,
		url: URL?
	) {
		self.id = id
		self.date = date
		self.title = title
		self.author = author
		self.content = content
		self.url = url
	}
}
