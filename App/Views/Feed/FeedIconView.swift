import SwiftUI

struct FeedIconView: View {
	let source: URL
	@AppStorage var iconData: Data?

	init(source: URL) {
		self.source = source
		_iconData = AppStorage(.iconKey(source: source))
	}
	
	var icon: Image {
		iconData
			.flatMap { UIImage(data: $0) }
			.flatMap { Image(uiImage: $0).resizable() }
		?? Image(.rss).renderingMode(.template).resizable()
	}
	
	var body: some View {
		ZStack {
			icon
			LoadingOverlayView(source: source)
		}
	}
}
