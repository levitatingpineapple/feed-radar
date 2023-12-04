import SwiftUI

struct FeedIconView: View {
	let source: URL
	@AppStorage var iconData: Data?
	@ObservedObject var fetching: Fetcher = .shared
	
	init(source: URL) {
		self.source = source
		_iconData = AppStorage(.iconKey(source: source))
	}
	
	var isFetching: Bool {
		fetching.tasks.contains(source)
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
				.blur(radius: isFetching ? 2 : 0)
				.opacity(isFetching ? 0.2 : 1)
			ProgressView()
				.frame(width: 32, height: 32)
				.opacity(isFetching ? 1 : 0)
		}.animation(.easeInOut(duration: 0.2), value: isFetching)
	}
}
