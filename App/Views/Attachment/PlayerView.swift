import SwiftUI
import AVKit

struct PlayerView: View {
	@State var model: Model
	
	var body: some View {
		VStack(spacing: .zero) {
			PlayerViewController(player: model.player, artwork: model.artwork)
				.aspectRatio(model.aspectRatio, contentMode: .fit)
			ChaptersView(playerModel: model)
		}
	}
}

extension PlayerView {
	
	/// Coordinates interactions between ``PlayerViewController`` and ``ChaptersView``
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
			) { [weak self] cmTime in self?.update(time: cmTime.seconds) }
			
			Task { @MainActor [weak self] in
				self?.metadata = try? await MetadataLoader().metadata(url: url)
			}
			Task { @MainActor [weak self] in
				self?.playerAspectRatio = try? await self?.player.aspectRatio()
			}
			Task { @MainActor [weak self] in
				if let content = item.content {
					self?.descriptionChapters = Array<Metadata.Chapter>(
						description: content
					)
					if let duration = try? await self?.player.duration() {
						if let lastChapter = self?.descriptionChapters?.popLast() {
							self?.descriptionChapters?.append(
								lastChapter.ending(in: duration)
							)
						}
					}
				}
			}
		}
		
		deinit {
			// TODO: The player is not getting deallocated, investigate the memory leak
			player.pause()
			player.seek(to: .zero)
			player.replaceCurrentItem(with: nil)
			if let timeObserver { player.removeTimeObserver(timeObserver) }
		}
		
		/// Seeks to the beginning of the chapter.
		/// Applies chapter art and triggers playback
		func seekTo(chapter: Metadata.Chapter) {
			currentChapter = chapter
			currentTime = chapter.startTime
			isSeeking = true
			player.seek(
				to: CMTime(timeInterval: chapter.startTime),
				toleranceBefore: .zero,
				toleranceAfter: CMTime(timeInterval: 0.5)
			) { [weak self] success in
				if success {
					self?.isSeeking = false
					self?.player.play()
				}
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

extension AVPlayer {
	func aspectRatio() async throws -> Double? {
		if let tracks = try await currentItem?.asset.load(.tracks) {
			for track in tracks {
				let naturalSize = try await track.load(.naturalSize)
				if let aspectRatio = naturalSize.aspectRatio { return aspectRatio }
			}
		}
		return nil
	}
	
	func duration() async throws -> Double? {
		try await currentItem?.asset.load(.duration).seconds
	}
}
