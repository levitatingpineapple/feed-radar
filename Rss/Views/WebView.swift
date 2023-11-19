import SwiftUI
import SafariServices

struct SafariWebView: UIViewControllerRepresentable {
	let url: URL
	
	func makeUIViewController(context: Context) -> SFSafariViewController {
		SFSafariViewController(url: url, entersReaderIfAvailable: true)
	}
	
	func updateUIViewController(_ viewController: SFSafariViewController, context: Context) {
	}
}
