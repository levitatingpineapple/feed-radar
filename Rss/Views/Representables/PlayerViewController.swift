import SwiftUI
import AVKit

struct PlayerViewController: UIViewControllerRepresentable {
	let url: URL
	@Binding var aspectRatio: Double
	
	func makeUIViewController(context: Context) -> AVPlayerViewController {
		let player = AVPlayer(url: url)
		try! AVAudioSession
			.sharedInstance()
			.setCategory(.playback, mode: .moviePlayback)
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
		let playerViewController = AVPlayerViewController()
		playerViewController.view?.backgroundColor = .clear
		playerViewController.player = player
		playerViewController.showsPlaybackControls = true
		return playerViewController
	}
	
	func updateUIViewController(
		_ playerViewController: AVPlayerViewController,
		context: Context
	) { }
}
