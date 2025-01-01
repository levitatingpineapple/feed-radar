import SwiftUI
import AVKit
import os.log

struct PlayerView: View {
	let invalidateSize: () -> Void
	@State var model: Model
	
	var body: some View {
		VStack(spacing: .zero) {
			PlayerViewController(player: model.player, artwork: model.artwork)
				.aspectRatio(model.aspectRatio, contentMode: .fit)
			chapters
		}
		.onChange(of: model.chapters) { invalidateSize() }
		.onChange(of: model.aspectRatio) { invalidateSize() }
	}
	
	@ViewBuilder
	private var chapters: some View {
		if let chapters = model.chapters, !chapters.isEmpty {
			VStack(alignment: .leading, spacing: .zero) {
				ForEach(chapters) { chapter in
					HStack {
						// TODO: Line limit might not be needed after implementing custom layout
						Text((chapter.title ?? "Chapter")).lineLimit(1)
						Spacer()
						if let time = model.time(of: chapter) {
							Text(time).bold()
								.monospacedDigit()
								.foregroundStyle(.secondary)
						}
					}
					.contentShape(Rectangle())
					.onTapGesture { Task { await model.seek(to: chapter) } }
					.padding(.vertical, 4)
					.padding(.horizontal, 8)
					.background {
						if chapter == model.currentChapter {
							ZStack(alignment: .leading) {
								Color(uiColor: .tertiarySystemBackground)
								GeometryReader { geometry in
									if let progress = model.progress(of: chapter) {
										Color.accentColor.opacity(0.6)
										// TODO: Invalid frame dimension
											.frame(width: progress * geometry.size.width)
											.animation(.default, value: model.currentTime)
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

extension PlayerView {
	/// Coordinates interactions between ``PlayerViewController`` and ``ChaptersView``
	@MainActor
	@Observable
	final class Model {
		let item: Item
		let player: AVPlayer
		var currentTime: TimeInterval?
		var currentChapter: Metadata.Chapter?
		private var metadata: Metadata?
		private var descriptionChapters: Array<Metadata.Chapter>?
		var chapters: Array<Metadata.Chapter>? {
			metadata?.chapters
			?? descriptionChapters
		}
		var artwork: UIImage? {
			if playerAspectRatio == nil {
				currentChapter?.artwork
				?? metadata?.artwork
			} else {
				nil
			}
		}
		
		var aspectRatio: Double {
			playerAspectRatio
			?? artwork?.size.aspectRatio
			?? 16 / 9
		}
		
		func time(of chapter: Metadata.Chapter) -> String? {
			DateComponentsFormatter.minutesSeconds.string(
				from: chapter == currentChapter
				? currentTime.flatMap { $0 - chapter.endTime } ?? chapter.duration
				: chapter.duration
			)
		}
		
		func progress(of chapter: Metadata.Chapter) -> Double? {
			if let currentTime,
			   let currentChapter,
			   chapter == currentChapter,
			   currentChapter.duration > 1 {
				(currentTime - chapter.startTime) / (chapter.duration - 1)
			} else { nil }
		}
		
		private var playerAspectRatio: Double?
		
		/// Observes player position and updates ``currentTime`` and ``currentChapter``
		nonisolated(unsafe)
		private var timeObserver: Any?
		
		/// Used to prevent observer updating ``currentTime`` during seek
		private var isSeeking = false
		
		init(url: URL, item: Item) {
			self.item = item
			let playerItem = AVPlayerItem(url: url)
			let title = AVMutableMetadataItem()
			title.identifier = .commonIdentifierTitle
			title.value = item.title as NSString
			playerItem.externalMetadata.append(title)
			if let imageData = UserDefaults.standard.data(forKey: .iconKey(source: item.source)) {
				let image = AVMutableMetadataItem()
				image.identifier = .commonIdentifierArtwork
				image.value = imageData as NSData
				playerItem.externalMetadata.append(image)
			}
			self.player = AVPlayer(playerItem: playerItem)
			timeObserver = player.addPeriodicTimeObserver(
				forInterval: CMTime(timeInterval: 1),
				queue: nil
			) { cmTime in
				print(cmTime.seconds)
				DispatchQueue.main.async {
					self.update(time: cmTime.seconds)
				}
			}

			// Load metadata
			Task {
				switch await loadMetadata(from: url) {
				case let .success(metadata): self.metadata = metadata
				case let .failure(error): Logger.ui.log("Metadata loading failed: \(error)")
				}
			}
			
			// Set aspect ratio
			Task {
				playerAspectRatio = try? await player.aspectRatio()
			}
			
			// Load chapters
			Task {
				if let content = item.content {
					descriptionChapters = Array<Metadata.Chapter>(
						description: content
					)
					if let duration = try? await player.duration() {
						if let lastChapter = descriptionChapters?.popLast() {
							descriptionChapters?.append(
								lastChapter.ending(in: duration)
							)
						}
					}
				}
			}
			
			func test() async {
				playerAspectRatio = try? await player.aspectRatio()
			}
		}
		
		deinit {
			// TODO: The player is not getting deallocated, investigate the memory leak
			player.pause()
			player.seek(to: .zero)
			player.replaceCurrentItem(with: nil)
			if let timeObserver { player.removeTimeObserver(timeObserver) }
		}
		
		func seek(to chapter: Metadata.Chapter) async {
			currentChapter = chapter
			currentTime = chapter.startTime
			isSeeking = true
			if await player.seek(
				to: CMTime(timeInterval: chapter.startTime),
				toleranceBefore: .zero,
				toleranceAfter: CMTime(timeInterval: 0.5)
			) {
				isSeeking = false
				player.play()
			}
		}
		
		private func update(time: TimeInterval) {
			if isSeeking == true { return }
			currentTime = time.rounded(.down)
			if let newCurrentChapter = chapters?
				.first(where: { time < $0.endTime && time >= $0.startTime }) {
				/// Set ``currentChapter`` manually, so that views
				/// which do not display time don't have to redraw on every ``currentTime`` update
				if newCurrentChapter != currentChapter { currentChapter = newCurrentChapter }
			}
		}
	}
}

// Assume track to be sendable
extension AVAssetTrack: @retroactive @unchecked Sendable { }

extension AVPlayer {
	func aspectRatio() async throws -> Double? {
		var ratio: Double?
		if let tracks = try await currentItem?.asset.load(.tracks) {
			for track in tracks {
				let naturalSize = try await track.load(.naturalSize)
				if let aspectRatio = naturalSize.aspectRatio {
					ratio = aspectRatio
					break
				}
			}
		}
		return ratio
	}
	
	func duration() async throws -> Double? {
		try await currentItem?.asset.load(.duration).seconds
	}
}
