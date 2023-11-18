import SwiftUI

struct IconView: View {
	let feed: Feed
	let size: Double
	
	var image: Image? {
#if os(iOS)
		feed.icon
			.flatMap { UIImage(data: $0) }
			.flatMap { Image(uiImage: $0) }
#elseif os(macOS)
		feed.icon
			.flatMap { NSImage(data: $0) }
			.flatMap { Image(nsImage: $0) }
#endif
	}
	
	var body: some View {
		(image ?? Image(systemName: "globe"))
			.resizable()
			.scaledToFit()
			.frame(maxWidth: size, maxHeight: size)
			.clipShape(RoundedRectangle(cornerRadius: size / 4, style: .continuous))
	}
}
