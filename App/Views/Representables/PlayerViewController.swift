import SwiftUI
import AVKit

struct PlayerViewController: UIViewControllerRepresentable {
	let url: URL
	/// Used to display title and feed artwork in the lock screen
	let item: Item?
	/// Aspect ratio is set after loading asset's video track
	@Binding var aspectRatio: Double
	
	func makeUIViewController(context: Context) -> AVPlayerViewController {
		try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
		let playerViewController = AVPlayerViewController()
		playerViewController.player = AVPlayer()
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
			player.seek(to: .zero)
			player.replaceCurrentItem(with: nil)
			(playerViewController.contentOverlayView?.subviews.first as? UIImageView)?.image = nil
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
			Task { [weak player] in
				if let tracks = try? await player?.currentItem?.asset.load(.tracks) {
					for track in tracks {
						let naturalSize = try await track.load(.naturalSize)
						if naturalSize != .zero {
							aspectRatio = naturalSize.width / naturalSize.height
							break
						}
					}
				}
			}
			
			// Display Album art
			Task {
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
					if let artwork = try? await playerItem.asset.artwork() {
						(playerViewController.contentOverlayView?.subviews.first as! UIImageView).image = artwork
						if artwork.size.height != .zero {
							aspectRatio = artwork.size.height / artwork.size.height
						}
					}
				}
			}
		}
	}
}
extension AVAsset {
	
	func metadata() async throws -> Array<AVMetadataItem>? {
		try await withCheckedThrowingContinuation { continuation in
			loadMetadata(for: .id3Metadata) { metadata, error in
				if let error {
					continuation.resume(throwing: error)
				} else {
					continuation.resume(returning: metadata)
				}
			}
		}
	}
	
	func artwork() async throws -> UIImage? {
		try await metadata()?
			.filter { $0.commonKey == .commonKeyArtwork }
			.first?
			.load(.dataValue)
			.flatMap { UIImage(data: $0) }
	}
}
