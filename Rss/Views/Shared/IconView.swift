import SwiftUI

struct IconView: View {
	@AppStorage var icon: Data?
	let feed: Feed
	let size: Double
	
	init(feed: Feed, size: Double) {
		_icon = AppStorage(feed.source.absoluteString)
		self.feed = feed
		self.size = size
	}
	
	var image: Image? {
		icon
			.flatMap { UIImage(data: $0) }
			.flatMap { Image(uiImage: $0) }
	}
	
	var body: some View {
		(image ?? Image(.rss).renderingMode(.template))
			.resizable()
			.scaledToFit()
			.padding(image == nil ? 2 : 0)
			.frame(maxWidth: size, maxHeight: size)
			.background(Color(.tertiarySystemBackground))
			.clipShape(RoundedRectangle(cornerRadius: size / 4, style: .continuous))
	}
}
