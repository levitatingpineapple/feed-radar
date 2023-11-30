import SwiftUI

struct IconView: View {
	@AppStorage var icon: Data?
	
	init(feed: Feed) {
		_icon = AppStorage(.iconKey(source: feed.source))
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
			.frame(width: 32, height: 32)
			.background(Color(.tertiarySystemBackground))
			.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
	}
}
