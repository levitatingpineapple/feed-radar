import Testing
import Foundation
@testable import Core

@Suite
struct ChapterDecoding {
	@Test func simple() {
		#expect(
			[Metadata.Chapter](
				description: "0:00 A<br>0:01 B<br>0:02 C<br>0:03 D"
			) == [
				Metadata.Chapter(startTime: 0, endTime: 1, title: "A", artwork: nil),
				Metadata.Chapter(startTime: 1, endTime: 2, title: "B", artwork: nil),
				Metadata.Chapter(startTime: 2, endTime: 3, title: "C", artwork: nil),
				Metadata.Chapter(startTime: 3, endTime: 3, title: "D", artwork: nil),
			],
			"These chapter should be valid"
		)
	}
	
	@Test func emptyLine() {
		#expect(
			Array<Metadata.Chapter>(
				description: "0:00 A<br>0:01 B<br>0:02 C<br>0:03 D<br>NOT A CHAPTER<br>0:04 E"
			) == [
				Metadata.Chapter(startTime: 0, endTime: 1, title: "A", artwork: nil),
				Metadata.Chapter(startTime: 1, endTime: 2, title: "B", artwork: nil),
				Metadata.Chapter(startTime: 2, endTime: 3, title: "C", artwork: nil),
				Metadata.Chapter(startTime: 3, endTime: 3, title: "D", artwork: nil)
			],
			"Decoding must stop at first line, which is not a chapter"
		)
	}
	
	@Test func startTime() {
		#expect(
			Array<Metadata.Chapter>(
				description: "0:01 A<br>0:02 B<br>0:03 C<br>0:04 D"
			) == nil,
			"Chapters must start from 0:00"
		)
	}
	
	@Test func ordering() {
		#expect(
			Array<Metadata.Chapter>(
				description: "0:01 A<br>0:03 B<br>0:02 C<br>0:04 D"
			) == nil,
			"Chapters must be ordered"
		)
	}
	
	@Test func orderingTimeFormatting() {
		#expect(
			Array<Metadata.Chapter>(
				description: "0:00 A<br>12:34 B<br>1:23:45 C<br>12:34:56 D"
			) == [
				Metadata.Chapter(startTime: 0, endTime: 754, title: "A", artwork: nil),
				Metadata.Chapter(startTime: 754, endTime: 5025, title: "B", artwork: nil),
				Metadata.Chapter(startTime: 5025, endTime: 45296, title: "C", artwork: nil),
				Metadata.Chapter(startTime: 45296, endTime: 45296, title: "D", artwork: nil)
			],
			"Chapters can have various time formatting"
		)
	}
	
	@Test func OrderingSamples() {
		let url = Bundle.module.url(forResource: "descriptions", withExtension: "html")!
		let descriptions = try! String(contentsOf: url, encoding: .utf8)
			.components(separatedBy: .newlines)
		for (description, chaptersCount) in zip(descriptions, [42, 5, 7]) {
			#expect(
				Array<Metadata.Chapter>(
					description: description
				)?.count == chaptersCount,
				"Description sample chapter count should match"
			)
		}
	}
}
