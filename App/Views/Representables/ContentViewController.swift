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
			viewController.headerController.rootView = AttachmentsView(item: item)
			cache.item = item
			
			viewController.webView.alpha = .zero
			UIView.animate(withDuration: 0.5, delay: 0.1) {
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
	
	// The `EnvironmentValues` is used to infer the colors used by the `WebView`s style
	// Observing it however will cause many unneeded updates
	// Cache helps to filter out updates, which does not affect the `ViewController`
	class Cache {
		var item: Item? = nil
		var html: Html? = nil
	}
	
	class ViewController: UIViewController {
		
		class HeaderController<Content: View>: UIHostingController<Content> {
			override func viewWillLayoutSubviews() {
				super.viewWillLayoutSubviews()
				parent?.view.setNeedsLayout()
			}
		}

		class HostingWebView: WKWebView {
			weak var headerView: UIView?
			
			override func layoutSubviews() {
				super.layoutSubviews()
				layoutHeader()
			}
			
			private var retainedHeaderSize: CGSize?
			
			func layoutHeader() {
				if let headerView {
					let headerSize = headerView.systemLayoutSizeFitting(
						CGSize(width: bounds.width, height: .infinity)
					)
					if retainedHeaderSize != headerSize {
						retainedHeaderSize = headerSize
					} else { return }
					scrollView.contentInset.top = headerSize.height
					scrollView.contentOffset.y += scrollView.contentInset.top - headerSize.height
					headerView.frame = CGRect(
						origin: CGPoint(x: .zero, y: -headerSize.height),
						size: headerSize
					)
				}
			}
		}
		
		let headerController = HeaderController<AttachmentsView?>(rootView: .none)
		let webView = HostingWebView()
		
		init() {
			super.init(nibName: nil, bundle: nil)
			super.viewDidLoad()
			view = webView
			webView.navigationDelegate = self
			webView.isOpaque = false
			webView.backgroundColor = .clear
			view = webView
			addChild(headerController)
			headerController.didMove(toParent: self)
			headerController.view.backgroundColor = .clear
			webView.scrollView.addSubview(headerController.view)
			webView.headerView = headerController.view
		}
		
		required init?(coder: NSCoder) { fatalError() }
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
