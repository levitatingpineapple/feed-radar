import Foundation
import RegexBuilder
import OutcastID3

import SwiftUI

public struct Metadata: Hashable, Equatable, Sendable {
	public let chapters: Array<Chapter>
	public let artwork: Artwork?
	
	public init(frames: Array<OutcastID3TagFrame>) {
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
	public struct Chapter: Hashable, Equatable, Identifiable, Sendable {
		public let startTime: TimeInterval
		public let endTime: TimeInterval
		public let title: String?
		public let artwork: Artwork?
		
		public var id: TimeInterval { startTime }
		public var duration: TimeInterval { endTime - startTime }

		/// Returns a new chapter with a updated end time
		public func ending(in endTime: TimeInterval) -> Chapter {
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
	public init(chapterFrame: OutcastID3.Frame.ChapterFrame) {
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

extension DateComponentsFormatter {
	public static let minutesSeconds = {
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.hour, .minute, .second]
		formatter.unitsStyle = .positional
		return formatter
	}()
}

extension Array where Element == Metadata.Chapter {

	/// Generates metadata chapters from a video `description`
	public init?(description: String) {
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
	public struct Match: Sendable {
		private let hours: TimeInterval
		private let minutes: TimeInterval
		private let seconds: TimeInterval
		public let title: String
		
		public var startTime: TimeInterval { 3600 * hours + 60 * minutes + seconds }
		
		public init?(substring: Substring) {
			let regex = Regex {
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
			if let match = try? regex.firstMatch(in: substring) {
				hours = match.1.flatMap { Double($0) } ?? .zero
				minutes = Double(match.2) ?? .zero
				seconds = Double(match.3) ?? .zero
				title = String(match.4)
			} else {
				return nil
			}
		}
	}
	
	public init(match: Match, endTime: TimeInterval) {
		startTime = match.startTime
		self.endTime = endTime
		self.title = match.title
		self.artwork = nil
	}
}

// Enable conditional image type, to allow testing on MacOS
public typealias Artwork = OutcastID3.Frame.PictureFrame.Picture.PictureImage
extension Artwork: @unchecked @retroactive Sendable { }
