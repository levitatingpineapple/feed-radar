import SwiftUI
import AVKit
import Core

struct PlayerViewController: UIViewControllerRepresentable {
	let player: AVPlayer
	let artwork: UIImage?

	func makeUIViewController(context: Context) -> AVPlayerViewController {
		try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
		let controller = AVPlayerViewController()
		controller.contentOverlayView!.addSubview(UIImageView())
		controller.allowsPictureInPicturePlayback = true
		if let overlayView = controller.contentOverlayView {
			overlayView.addSubview(controller.artworkView)
			controller.artworkView.contentMode = .scaleAspectFit
			controller.artworkView.translatesAutoresizingMaskIntoConstraints = false
			NSLayoutConstraint.activate([
				controller.artworkView.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor),
				controller.artworkView.trailingAnchor.constraint(equalTo:  overlayView.trailingAnchor),
				controller.artworkView.topAnchor.constraint(equalTo: overlayView.topAnchor),
				controller.artworkView.bottomAnchor.constraint(equalTo: overlayView.bottomAnchor)
			])
		}
		return controller
	}

	func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
		DispatchQueue.main.async {
			controller.player = player
			controller.artworkView.image = artwork
		}
	}
}

extension AVPlayerViewController {
	fileprivate var artworkView: UIImageView {
		contentOverlayView?.subviews.first as! UIImageView
	}
}
