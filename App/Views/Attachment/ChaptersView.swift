import SwiftUI

struct ChaptersView: View {
	@ObservedObject var chapterCoordinator: PlayerViewController.ChapterCoordinator
	
	var body: some View {
		if let chapters = chapterCoordinator.metadata?.chapters, !chapters.isEmpty {
			VStack(alignment: .leading, spacing: .zero) {
				ForEach(chapters) { chapter in
					ZStack {
						HStack {
							Text((chapter.title ?? "Chapter"))
							Spacer()
							if let time = formattedTime(chapter: chapter) {
								Text(time).bold()
									.monospacedDigit()
									.foregroundStyle(.secondary)
							}
						}
						.contentShape(Rectangle())
						.onTapGesture { chapterCoordinator.seekTo(chapter: chapter) }
						.padding(.vertical, 4)
						.padding(.horizontal, 8)
						.background {
							if chapter == chapterCoordinator.currentChapter {
								ZStack(alignment: .leading) {
									Color(uiColor: .tertiarySystemBackground)
									GeometryReader { geometry in
										Color.accentColor.opacity(0.5)
											.frame(width: geometry.size.width * (progress(of: chapter) ?? .zero))
											.animation(.default, value: chapterCoordinator.currentTime)
									}
								}
							}
						}
						.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
					}
				}
			}
			.padding(10)
			Divider()
		}
	}
	
	private func formattedTime(chapter: Metadata.Chapter) -> String? {
		DateComponentsFormatter.minutesSeconds.string(
			from: chapter == chapterCoordinator.currentChapter
			? chapterCoordinator.currentTime
				.flatMap { $0 - chapter.endTime } ?? chapter.duration
			: chapter.duration
		)
	}
	
	private func progress(of chapter: Metadata.Chapter) -> Double? {
		chapterCoordinator.currentTime
			.flatMap { ($0 - chapter.startTime) / chapter.duration }
	}
}
