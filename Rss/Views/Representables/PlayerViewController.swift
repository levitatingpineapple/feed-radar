import SwiftUI
import AVKit

struct PlayerViewController: UIViewControllerRepresentable {
	let url: URL
	@Binding var aspectRatio: Double
	
	static let shared: AVPlayerViewController = {
		try! AVAudioSession
			.sharedInstance()
			.setCategory(.playback, mode: .moviePlayback)
		let playerViewController = AVPlayerViewController()
		playerViewController.view?.backgroundColor = .clear
		playerViewController.showsPlaybackControls = true
		playerViewController.player = AVPlayer()
		return playerViewController
	}()
	
	func makeUIViewController(context: Context) -> AVPlayerViewController {
		let shared = PlayerViewController.shared
		if let player = shared.player {
			player.pause()
			player.replaceCurrentItem(with: nil)
			player.replaceCurrentItem(with: AVPlayerItem(url: url))
		}
		return shared
	}
	
	func updateUIViewController(
		_ playerViewController: AVPlayerViewController,
		context: Context
	) {
		if let player = playerViewController.player {
			player.pause()
			player.replaceCurrentItem(with: nil)
			player.replaceCurrentItem(with: AVPlayerItem(url: url))
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
