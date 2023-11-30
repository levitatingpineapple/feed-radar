import SwiftUI
import AVKit

struct PlayerViewController: UIViewControllerRepresentable {
	let url: URL
	@Binding var aspectRatio: Double
	
	func makeUIViewController(context: Context) -> AVPlayerViewController {
		try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
		let playerViewController = AVPlayerViewController()
		playerViewController.view?.backgroundColor = .clear
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
			player.replaceCurrentItem(with: nil)
			let playerItem = AVPlayerItem(url: url)
			if let item = Store.shared.item {
				let title = AVMutableMetadataItem()
				title.identifier = AVMetadataIdentifier.commonIdentifierTitle
				title.value = (item.title ?? item.itemId) as NSString
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
		}
	}
}
