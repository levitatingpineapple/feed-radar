import SwiftUI

struct ChaptersView: View {
	let playerModel: PlayerView.Model
	
	var body: some View {
		if let chapters = playerModel.chapters, !chapters.isEmpty {
			VStack(alignment: .leading, spacing: .zero) {
				ForEach(chapters) { chapter in
					HStack
						{// TODO: Line limit might not be needed after implementing custom layout
						Text((chapter.title ?? "Chapter")).lineLimit(1)
						Spacer()
						if let time = playerModel.time(of: chapter) {
							Text(time).bold()
								.monospacedDigit()
								.foregroundStyle(.secondary)
						}
					}
					.contentShape(Rectangle())
					.onTapGesture { playerModel.seekTo(chapter: chapter) }
					.padding(.vertical, 4)
					.padding(.horizontal, 8)
					.background {
						if chapter == playerModel.currentChapter {
							ZStack(alignment: .leading) {
								Color(uiColor: .tertiarySystemBackground)
								GeometryReader { geometry in
									if let progress = playerModel.progress(of: chapter) {
										Color.accentColor.opacity(0.6)
											.frame(width: progress * geometry.size.width)
											.animation(.default, value: playerModel.currentTime)
									}
								}
							}
						}
					}
					.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
				}
			}
			.padding(10)
			Divider()
		}
	}
}
