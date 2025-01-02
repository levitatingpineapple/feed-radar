import SwiftUI
import WebKit
import SafariServices
import Core

struct SafariViewController: UIViewControllerRepresentable {
	let url: URL
	
	func makeUIViewController(
		context: Context
	) -> SafariViewController.Container { Container() }
	
	func updateUIViewController(
		_ container: SafariViewController.Container,
		context: Context
	) { container.load(url: url) }
}

extension SafariViewController {
	class Container: UIViewController {
		var safariViewController: SFSafariViewController?
		
		func load(url: URL) {
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
				let newController = SFSafariViewController(url: url)
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
