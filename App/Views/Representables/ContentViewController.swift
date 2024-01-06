
import UIKit
import SwiftUI
import WebKit

struct ContentViewController: UIViewControllerRepresentable {
	let htmlString: String
	let title: String
	let url: URL?
	let request: Attachment.Request
	@Binding var scale: Double
	
	func makeUIViewController(context: Context) -> ViewController {
		ViewController()
	}
	
	func updateUIViewController(
		_ viewController: ViewController,
		context: Context
	) {
		viewController.attachmentsController.rootView = AttachmentListView(
			title: title,
			request: request,
			scale: scale
		) { [weak viewController] in
			viewController?.attachmentsController.view.invalidateIntrinsicContentSize()
		}
		viewController.url = url
		viewController.webView.loadHTMLString(
			htmlString,
			baseURL: url
		)
	}
}

extension ContentViewController {
	class ViewController: UIViewController {
		let attachmentsController = UIHostingController<AttachmentListView?>(rootView: .none)
		let webView = WKWebView()
		var url: URL?
		private var observation: NSKeyValueObservation?
		
		deinit { observation = nil }
		
		override func viewDidLoad() {
			super.viewDidLoad()
			view = webView
			webView.navigationDelegate = self
			webView.isOpaque = false
			webView.backgroundColor = .clear
			addChild(attachmentsController)
			attachmentsController.view.backgroundColor = .clear
			webView.scrollView.addSubview(attachmentsController.view)
			attachmentsController.view.translatesAutoresizingMaskIntoConstraints = false
			attachmentsController.view.bottomAnchor.constraint(equalTo: webView.scrollView.topAnchor).isActive = true
			attachmentsController.view.widthAnchor.constraint(equalTo: webView.widthAnchor).isActive = true
			attachmentsController.view.centerXAnchor.constraint(equalTo: webView.centerXAnchor).isActive = true
			
			// Updates content inset based height of the attachments, as they load.
			observation = attachmentsController.view.observe(\.bounds, options: [.new]) { [weak self] (view, change) in
				if let self,
				   let webContentHeight = change.newValue?.height,
				   webContentHeight != self.webView.scrollView.contentInset.top {
					self.webView.scrollView.contentInset.top = webContentHeight
					self.webView.scrollView.setContentOffset(
						CGPoint(x: .zero, y: -(self.webView.safeAreaInsets.top + webContentHeight)),
						animated: false
					)
					
				}
			}
		}
	}
	
}

extension ContentViewController.ViewController: WKNavigationDelegate {
	func webView(
		_ webView: WKWebView,
		decidePolicyFor navigationAction: WKNavigationAction,
		decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
	) {
		if let url = navigationAction.request.url,
		   // External url which is not an iframe opened in browser
		   url != self.url && navigationAction.targetFrame?.isMainFrame == true {
			decisionHandler(.cancel)
			UIApplication.shared.open(url)
		} else {
			decisionHandler(.allow)
		}
	}
}
