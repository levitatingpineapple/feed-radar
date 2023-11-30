
import UIKit
import SwiftUI
import WebKit

struct WebViewController: UIViewControllerRepresentable {
	let content: String
	let title: String
	let base: URL?
	let request: Attachment.Request
	@Binding var scale: Double
	
	func makeUIViewController(context: Context) -> ViewController {
		return ViewController(attachmentsView: attatchmentsView)
	}
	
	func updateUIViewController(
		_ viewController: ViewController,
		context: Context
	) {
		viewController.hc.rootView = attatchmentsView
		viewController.webView.loadHTMLString(
			content.wrappedInHtml(scale: scale),
			baseURL: base
		)
	}
	
	private var attatchmentsView: AttachmentsView {
		AttachmentsView(title: title, request: request, scale: scale)
	}
}

extension WebViewController {
	class ViewController: UIViewController {
		let hc: UIHostingController<AttachmentsView>
		let webView = WKWebView()
		
		init(attachmentsView: AttachmentsView) {
			hc = UIHostingController(rootView: attachmentsView)
			super.init(nibName: nil, bundle: nil)
		}
		
		@available(*, unavailable)
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		
		var timer: Timer!
		
		override func viewDidLoad() {
			super.viewDidLoad()
			view = webView
			webView.navigationDelegate = self
			webView.isOpaque = false
			webView.backgroundColor = .clear
			addChild(hc)
			hc.view.backgroundColor = .clear
			webView.scrollView.addSubview(hc.view!)
			hc.view.translatesAutoresizingMaskIntoConstraints = false
			hc.view.bottomAnchor.constraint(equalTo: webView.scrollView.topAnchor).isActive = true
			hc.view.widthAnchor.constraint(equalTo: webView.widthAnchor).isActive = true
			hc.view.centerXAnchor.constraint(equalTo: webView.centerXAnchor).isActive = true
			
			// TODO: Find way to observe intrinsic content change
			Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
				if let self {
					let webContentHeight = self.hc.view.intrinsicContentSize.height
					if webContentHeight != self.webView.scrollView.contentInset.top {
						self.webView.scrollView.contentInset.top = webContentHeight
						self.webView.scrollView.setContentOffset(
							CGPoint(x: .zero, y: -(self.webView.safeAreaInsets.top + webContentHeight)),
							animated: false
						)
						self.hc.view.invalidateIntrinsicContentSize()
					}
				} else {
					timer.invalidate()
				}
			}
		}
	}
	
}

extension WebViewController.ViewController: WKNavigationDelegate {
	func webView(
		_ webView: WKWebView,
		decidePolicyFor navigationAction: WKNavigationAction,
		decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
	) {
		if let url = navigationAction.request.url,
		   // External url which is not an iframe opened in browser
		   url != webView.url && navigationAction.targetFrame?.isMainFrame == true {
			decisionHandler(.cancel)
			UIApplication.shared.open(url)
		} else {
			decisionHandler(.allow)
		}
	}
}
