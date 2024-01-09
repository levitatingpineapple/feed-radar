import SwiftUI
import AVKit

struct PlayerViewController: UIViewControllerRepresentable {
	let url: URL
	
	/// Used to display title and feed artwork in the lock screen
	let item: Item?
	
	/// Created injected and observed by the parent.
	/// Coordinator's lifecycle managed using StateObject.
	weak var chapterCoordinator: ChapterCoordinator!
	
	func makeCoordinator() -> ChapterCoordinator { chapterCoordinator }
	
	func makeUIViewController(context: Context) -> AVPlayerViewController {
		try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
		let playerViewController = AVPlayerViewController()
		playerViewController.player = AVPlayer()
		context.coordinator.set(playerViewController)
		return playerViewController
	}
	
	static func dismantleUIViewController(_ playerViewController: AVPlayerViewController) {
		if let player = playerViewController.player {
			player.replaceCurrentItem(with: nil)
		}
	}
	
	func updateUIViewController(
		_ playerViewController: AVPlayerViewController,
		context: Context
	) {
		if let player = playerViewController.player {
			
			// Clean up the player
			player.pause()
			player.seek(to: .zero)
			player.replaceCurrentItem(with: nil)
			playerViewController.artworkView?.image = nil
			
			// Create new Item and apply external lockscreen metadata
			let playerItem = AVPlayerItem(url: url)
			if let item {
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
			}
			player.replaceCurrentItem(with: playerItem)
			
			// Load aspect ratio from video track
			Task { [weak player] in
				if let tracks = try? await player?.currentItem?.asset.load(.tracks) {
					for track in tracks {
						let naturalSize = try await track.load(.naturalSize)
						if naturalSize != .zero {
							context.coordinator.aspectRatio = naturalSize.width / naturalSize.height
							break
						}
					}
				}
			}
			
			// Load Metadata
			// TODO: Apply artwork image, only if no video track if found
			Task {
				let metadataLoader = MetadataLoader()
				context.coordinator.metadata = try? await metadataLoader.metadata(url: url)

				if let overlayView = playerViewController.contentOverlayView {
					if overlayView.subviews.isEmpty {
						let imageView = UIImageView()
						imageView.contentMode = .scaleAspectFit
						imageView.isUserInteractionEnabled = false
						imageView.translatesAutoresizingMaskIntoConstraints = false
						overlayView.addSubview(imageView)
						NSLayoutConstraint.activate([
							imageView.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor),
							imageView.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor),
							imageView.topAnchor.constraint(equalTo: overlayView.topAnchor),
							imageView.bottomAnchor.constraint(equalTo: overlayView.bottomAnchor)
						])
					}
					if let artwork = chapterCoordinator?.metadata?.artwork {
						playerViewController.artworkView?.image = artwork
						if artwork.size.height != .zero {
							context.coordinator.aspectRatio = artwork.size.height / artwork.size.height
						}
					}
				}
			}
		}
	}
}

extension AVPlayerViewController {
	var artworkView: UIImageView? {
		contentOverlayView?.subviews.first as? UIImageView
	}
}

extension CMTime {
	init(timeInterval: TimeInterval) {
		self = CMTime(
			seconds: timeInterval,
			preferredTimescale: CMTimeScale(NSEC_PER_SEC)
		)
	}
}
