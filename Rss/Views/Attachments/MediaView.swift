import SwiftUI

struct MediaView: View {
	let attachment: Attachment
	@State private var aspectRatio: Double = 16 / 9
	
	var body: some View {
		if attachment.type.conforms(to: .image) {
			AsyncImage(url: attachment.url) {
				switch $0 {
				case .success(let image):
					image
						.resizable()
						.aspectRatio(contentMode: .fit)
				default:
					EmptyView()
				}
			}
		} else if attachment.type.conforms(to: .audiovisualContent) {
			PlayerViewController(url: attachment.url, aspectRatio: $aspectRatio)
				.frame(minHeight: 150)
				.aspectRatio(aspectRatio, contentMode: .fit)
		}
	}
}
