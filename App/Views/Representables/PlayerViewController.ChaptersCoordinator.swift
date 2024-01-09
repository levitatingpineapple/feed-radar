import SwiftUI
import AVKit

extension PlayerViewController {
	
	/// Coordinates interactions between ``PlayerViewController`` and ``ChaptersView``
	class ChapterCoordinator: ObservableObject {
		@Published var metadata: Metadata?
		@Published var aspectRatio: Double?
		@Published var currentTime: TimeInterval?
		@Published var currentChapter: Metadata.Chapter?
		
		private weak var playerViewController: AVPlayerViewController?
		/// Observes player position and updates ``currentTime`` and ``currentChapter``
		private var timeObserver: Any?
		/// Used to prevent observer updating ``currentTime`` durin seek
		private var isSeeking = false
		
		deinit {
			if let timeObserver {
				playerViewController?.player?.removeTimeObserver(timeObserver)
			}
		}
		
		/// Creates a weak refrence to ``PlayerViewController``
		/// and adds an observer, which drives the ``currentTime``
		func set(_ playerViewController: AVPlayerViewController) {
			self.playerViewController = playerViewController
			playerViewController.player?.addPeriodicTimeObserver(
				forInterval: CMTime(timeInterval: 1),
				queue: nil
			) { [weak self] cmTime in
				self?.update(time: cmTime.seconds)
			}
		}
		
		/// Seeks to the beginning of the chapter.
		/// Applies chapter art and triggers playback
		func seekTo(chapter: Metadata.Chapter) {
			currentChapter = chapter
			currentTime = chapter.startTime
			isSeeking = true
			playerViewController?.artworkView?.image = chapter.artwork ?? metadata?.artwork
			if let player = playerViewController?.player {
				player.pause()
				player.seek(to: CMTime(timeInterval: chapter.startTime)) { [weak self] success in
					if success { 
						self?.isSeeking = false
						player.play()
					}
				}
			}
		}
		
		private func update(time: TimeInterval) {
			if isSeeking == true { return }
			currentTime = time
			if let metadata,
			   let newCurrentChapter = metadata.chapters
				.first(where: { time < $0.endTime && time >= $0.startTime }) {
				if newCurrentChapter != currentChapter {
					currentChapter = newCurrentChapter
					playerViewController?.artworkView?.image = newCurrentChapter.artwork ?? metadata.artwork
				}
			}
		}
	}
}
