import SwiftUI

struct IconView: View {
	let feed: Feed
	let size: Double
	
	var image: Image? {
		feed.icon
			.flatMap { UIImage(data: $0) }
			.flatMap { Image(uiImage: $0) }
	}
	
	var body: some View {
		(image ?? Image(systemName: "globe"))
			.resizable()
			.scaledToFit()
//			.frame(maxWidth: size, maxHeight: size)
			.clipShape(RoundedRectangle(cornerRadius: size / 4, style: .continuous))
	}
}
