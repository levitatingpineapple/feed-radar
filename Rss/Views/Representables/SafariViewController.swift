import SwiftUI
import WebKit
import SafariServices

struct SafariViewController: UIViewControllerRepresentable {
	let url: URL
	let reader: Bool
	
	func makeUIViewController(
		context: Context
	) -> SafariViewController.Container { Container() }
	
	func updateUIViewController(
		_ container: SafariViewController.Container,
		context: Context
	) { container.load(url: url, reader: reader) }
}

extension SafariViewController {
	class Container: UIViewController {
		var safariViewController: SFSafariViewController?
		
		func load(url: URL, reader: Bool) {
			if let safariViewController {
				safariViewController.view.removeFromSuperview()
				safariViewController.removeFromParent()
			}
			if ProcessInfo.processInfo.isiOSAppOnMac {
				if let webView = view as? WKWebView {
					webView.load(URLRequest(url: url))
				} else {
					let webView = WKWebView()
					webView.load(URLRequest(url: url))
					view = webView
				}
			} else {
				let configuration = SFSafariViewController.Configuration()
				configuration.entersReaderIfAvailable = reader
				let newController = SFSafariViewController(url: url, configuration: configuration)
				addChild(newController)
				view.addSubview(newController.view)
				newController.view.translatesAutoresizingMaskIntoConstraints = false
				newController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
				newController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
				newController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
				newController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
				safariViewController = newController
			}
		}
	}
}
