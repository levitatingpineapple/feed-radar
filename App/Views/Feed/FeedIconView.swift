import SwiftUI

struct FeedIconView: View {
	private static let cache = NSCache<NSString, UIImage>()
	private let source: URL
	@AppStorage private var data: Data? // TODO: Move to the Store

	init(source: URL) {
		self.source = source
		_data = AppStorage(.iconKey(source: source))
	}

	var body: some View {
		Self._printChanges()
		return ZStack {
			icon.resizable()
			LoadingView(source: source)
		}
	}

	private var uiImage: UIImage? {
		if let cached = Self.cache.object(forKey: source.absoluteString as NSString) {
			return cached
		} else if let data, let uiImage = UIImage(data: data) {
			Self.cache.setObject(uiImage, forKey: source.absoluteString as NSString)
			return uiImage
		} else {
			return nil
		}
	}
	
	private var icon: Image {
		uiImage.map { Image(uiImage: $0) }
		?? Image(.rss).renderingMode(.template)
	}
}
