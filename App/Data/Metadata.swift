import UIKit
import RegexBuilder
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
	
	/// A Struct representing a section in some time based media
	/// It associates an optional title and artwork with a timerange
	struct Chapter: Hashable, Equatable, Identifiable {
		let startTime: TimeInterval
		let endTime: TimeInterval
		let title: String?
		let artwork: UIImage?
		
		var id: TimeInterval { startTime }
		var duration: TimeInterval { endTime - startTime }

		/// Returns a new chapter with a updated end time
		func ending(in endTime: TimeInterval) -> Chapter {
			Chapter(
				startTime: self.startTime,
				endTime: endTime,
				title: self.title,
				artwork: self.artwork
			)
		}
	}
}

extension Metadata.Chapter {
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
	
	nonisolated(unsafe)
	static private let regex = Regex {
		Optionally {
			Capture { Repeat(.digit, (1...2)) }
			":"
		}
		Capture { Repeat(.digit, (1...2)) }
		":"
		Capture { Repeat(.digit, count: 2) }
		" "
		Optionally {
			One(.anyOf("-–—"))
			" "
		}
		Capture {
			OneOrMore {
				CharacterClass.anyNonNewline
			}
		}
	}
	
	init(description: String, endTime: TimeInterval) {
		fatalError()
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

extension Array where Element == Metadata.Chapter {

	/// Generates metadata chapters from a video `description`
	init?(description: String) {
		self = Array<Metadata.Chapter>()
		let matches = description
			.split(separator: "<br>", maxSplits: 200)
			.map { Metadata.Chapter.Match(substring: $0) }
		for (match, nextMatch) in zip(matches, matches.dropFirst() + [nil]) {
			if let match, match.startTime >= last?.endTime ?? .zero {
				if let nextMatch {
					if isEmpty {
						// First Chapter
						if match.startTime == .zero {
							append(Metadata.Chapter(match: match, endTime: nextMatch.startTime))
						}
					} else {
						// Intermediate Chapters
						append(Metadata.Chapter(match: match, endTime: nextMatch.startTime))
					}
				} else if !isEmpty {
					// Last chapter
					append(Metadata.Chapter(match: match, endTime: match.startTime))
				}
			} else if !isEmpty {
				return // Return on first line which is not chapter
			}
		}
		if isEmpty { return nil }
	}
}

extension Metadata.Chapter {
	struct Match: Sendable {
		private let hours: TimeInterval
		private let minutes: TimeInterval
		private let seconds: TimeInterval
		let title: String
		
		var startTime: TimeInterval { 3600 * hours + 60 * minutes + seconds }
		
		nonisolated(unsafe)
		static private let regex = Regex {
			Optionally {
				Capture { Repeat(.digit, (1...2)) }
				":"
			}
			Capture { Repeat(.digit, (1...2)) }
			":"
			Capture { Repeat(.digit, count: 2) }
			" "
			Optionally {
				One(.anyOf("-–—")) // HYPHEN-MINUS, EN DASH, EM DASH
				" "
			}
			Capture {
				OneOrMore {
					CharacterClass.anyNonNewline
				}
			}
		}
		
		init?(substring: Substring) {
			if let match = try! Self.regex.firstMatch(in: substring) {
				hours = match.1.flatMap { Double($0) } ?? .zero
				minutes = Double(match.2) ?? .zero
				seconds = Double(match.3) ?? .zero
				title = String(match.4)
			} else {
				return nil
			}
		}
	}
	
	init(match: Match, endTime: TimeInterval) {
		startTime = match.startTime
		self.endTime = endTime
		self.title = match.title
		self.artwork = nil
	}
}
