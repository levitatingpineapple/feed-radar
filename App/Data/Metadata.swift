import UIKit
import OutcastID3

struct Metadata: Hashable, Equatable {
	let chapters: Array<Chapter>
	let artwork: UIImage?
	
	init(frames: Array<OutcastID3TagFrame>) {
		chapters = frames
			.compactMap { $0 as? OutcastID3.Frame.ChapterFrame }
			.map { Chapter(chapterFrame: $0) }
		artwork = frames
			.compactMap { ($0 as? OutcastID3.Frame.PictureFrame)?.picture.image }
			.first
	}
}

extension Metadata {
	struct Chapter: Hashable, Equatable, Identifiable {
		let startTime: TimeInterval
		let endTime: TimeInterval
		let title: String?
		let artwork: UIImage?
		
		var id: TimeInterval { startTime }
		var duration: TimeInterval { endTime - startTime }
		
		init(chapterFrame: OutcastID3.Frame.ChapterFrame) {
			startTime = chapterFrame.startTime
			endTime = chapterFrame.endTime
			title = chapterFrame.subFrames
				.compactMap { ($0 as? OutcastID3.Frame.StringFrame)?.str }
				.first
			artwork = chapterFrame.subFrames
				.compactMap { ($0 as? OutcastID3.Frame.PictureFrame)?.picture.image }
				.first
		}
	}
}

extension DateComponentsFormatter {
	static let minutesSeconds = {
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.hour, .minute, .second]
		formatter.unitsStyle = .positional
		return formatter
	}()
}
