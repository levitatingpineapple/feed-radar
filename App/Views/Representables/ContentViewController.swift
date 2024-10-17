import UIKit
import SwiftUI
@preconcurrency import WebKit

struct ContentViewController: UIViewControllerRepresentable {
	let display: ItemDetailView.Display
	let item: Item
	@Environment(\.self) var environment
	@State var cache = Cache()
	
	func makeUIViewController(context: Context) -> ViewController {
		ViewController()
	}
	
	func updateUIViewController(
		_ viewController: ViewController,
		context: Context
	) {
		if cache.item != item {
			viewController.attachmentsController.rootView = AttachmentsView(
				item: item
			) { [weak viewController] in
				viewController?.attachmentsController.view.invalidateIntrinsicContentSize()
			}
			cache.item = item
			
			viewController.webView.alpha = .zero
			UIView.animate(withDuration: 0.2, delay: 0.1) {
				viewController.webView.alpha = 1
			}
		}
		
		let html = Html(
			style: .style,
			body: body ?? String(),
			environmentValues: environment
		)
		
		// Item change is also checked, since two items can
		// have the same content (empty for example)
		if cache.html != html || cache.item != item {
			viewController.webView.loadHTMLString(
				html.string,
				baseURL: item.url
			)
			cache.html = html
		}
	}
	
	private var body: String? {
		switch display {
		case .content:
			item.content
		case .extractedContent:
			item.extracted
		case .webView:
			nil
		}
	}
}

extension ContentViewController {
	
	// The `EnvironmentValues` is used to infer the colors used by the `WebView`s style
	// Observing it however will cause many unneeded updates
	// Cache helps to filter out updates, which does not affect the `ViewController`
	class Cache {
		var item: Item? = nil
		var html: Html? = nil
	}
}

extension ContentViewController {
	class ViewController: UIViewController {
		let attachmentsController = UIHostingController<AttachmentsView?>(rootView: .none)
		private var observation: NSKeyValueObservation?
		
		var webView: WKWebView { view as! WKWebView }
		
		init() {
			super.init(nibName: nil, bundle: nil)
			super.viewDidLoad()
			view = WKWebView()
			webView.navigationDelegate = self
			webView.isOpaque = false
			webView.backgroundColor = .clear
			view = webView
			addChild(attachmentsController)
			attachmentsController.view.backgroundColor = .clear
			webView.scrollView.addSubview(attachmentsController.view)
			attachmentsController.view.translatesAutoresizingMaskIntoConstraints = false
			attachmentsController.view.bottomAnchor.constraint(equalTo: webView.scrollView.topAnchor).isActive = true
			attachmentsController.view.widthAnchor.constraint(equalTo: webView.widthAnchor).isActive = true
			attachmentsController.view.centerXAnchor.constraint(equalTo: webView.centerXAnchor).isActive = true
			
			// Updates content inset based height of the attachments, as they load.
			observation = attachmentsController.view.observe(\.bounds, options: [.new]) { [weak self] (view, change) in
				if let webView = self?.webView,
				   let webContentHeight = change.newValue?.height,
				   webContentHeight != .zero,
				   webContentHeight != webView.scrollView.contentInset.top {
					webView.scrollView.contentInset.top = webContentHeight
					webView.scrollView.setContentOffset(
						CGPoint(x: .zero, y: -(webView.safeAreaInsets.top + webContentHeight)),
						animated: false
					)
				}
			}
		}
		
		required init?(coder: NSCoder) { fatalError() }
		
		deinit {
			attachmentsController.rootView = .none
			attachmentsController.removeFromParent()
			observation = nil
		}
	}
}

extension ContentViewController.ViewController: WKNavigationDelegate {
	func webView(
		_ webView: WKWebView,
		decidePolicyFor navigationAction: WKNavigationAction,
		decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
	) {
		switch navigationAction.navigationType {
		case .linkActivated:
			decisionHandler(.cancel)
			if let url = navigationAction.request.url {
				UIApplication.shared.open(url)
			}
		default:
			decisionHandler(.allow)
		}
	}
}
